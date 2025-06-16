#!/bin/bash

# Sharp DRM Enhanced Driver Installation Script
# Version 2.0

set -e

DRIVER_NAME="sharp-drm-enhanced"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/sharp-drm-install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create log file with proper permissions
touch "$LOG_FILE" 2>/dev/null || {
    LOG_FILE="./sharp-drm-install.log"
    touch "$LOG_FILE" 2>/dev/null || {
        echo "Warning: Cannot create log file, proceeding without logging"
        LOG_FILE="/dev/null"
    }
}

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "$1"
}

log_info() {
    log "${BLUE}[INFO]${NC} $1"
}

log_success() {
    log "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    log "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Please do not run this script as root. Use sudo when needed."
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check for required packages
    local missing_packages=()
    
    if ! dpkg -l | grep -q raspberrypi-kernel-headers 2>/dev/null; then
        # Try alternative header packages for different systems
        if ! dpkg -l | grep -q linux-headers-$(uname -r) 2>/dev/null; then
            missing_packages+=("linux-headers-$(uname -r)")
        fi
    fi
    
    if ! dpkg -l | grep -q build-essential 2>/dev/null; then
        missing_packages+=("build-essential")
    fi
    
    if ! command -v dtc &> /dev/null; then
        missing_packages+=("device-tree-compiler")
    fi
    
    if [ ${#missing_packages[@]} -ne 0 ]; then
        log_warning "Missing packages: ${missing_packages[*]}"
        log_info "Installing missing packages..."
        sudo apt update
        sudo apt install -y "${missing_packages[@]}"
    fi
    
    # Check if we have kernel headers
    if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
        log_warning "Kernel headers not found at /lib/modules/$(uname -r)/build"
        log_info "You may need to install kernel headers for your system"
    fi
    
    log_success "Prerequisites check completed"
}

# Backup original driver
backup_original() {
    log_info "Backing up original driver..."
    
    local backup_dir="$HOME/sharp-drm-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -d "/var/tmp/jdi-drm-rpi" ]; then
        mkdir -p "$backup_dir"
        cp -r /var/tmp/jdi-drm-rpi/* "$backup_dir/" 2>/dev/null || true
        log_success "Original driver backed up to: $backup_dir"
    fi
    
    # Backup existing module if present
    local existing_ko="/lib/modules/$(uname -r)/extra/sharp-drm.ko"
    if [ -f "$existing_ko" ]; then
        sudo cp "$existing_ko" "${existing_ko}.backup" 2>/dev/null || true
        log_success "Existing module backed up"
    fi
}

# Build the driver
build_driver() {
    log_info "Building Sharp DRM Enhanced driver..."
    
    cd "$SCRIPT_DIR"
    
    # Clean previous builds
    make clean &>/dev/null || true
    
    # Check if we can build
    if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
        log_error "Cannot build: kernel headers not found"
        log_error "Please install kernel headers: sudo apt install linux-headers-$(uname -r)"
        exit 1
    fi
    
    # Build
    log_info "Compiling kernel module..."
    if make 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Driver built successfully"
    else
        log_error "Failed to build driver. Check $LOG_FILE for details."
        log_error "Common issues:"
        log_error "1. Missing kernel headers: sudo apt install linux-headers-\$(uname -r)"
        log_error "2. Missing build tools: sudo apt install build-essential"
        log_error "3. Incompatible kernel version"
        exit 1
    fi
}

# Install the driver
install_driver() {
    log_info "Installing Sharp DRM Enhanced driver..."
    
    cd "$SCRIPT_DIR"
    
    # Unload existing driver
    if lsmod | grep -q sharp_drm; then
        log_info "Unloading existing driver..."
        sudo modprobe -r sharp_drm 2>/dev/null || true
    fi
    
    # Install new driver
    log_info "Installing kernel module..."
    if sudo make install 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Driver installed successfully"
    else
        log_error "Failed to install driver. Check $LOG_FILE for details."
        exit 1
    fi
    
    # Install enhanced utilities
    if [ -f "monoset-enhanced" ]; then
        sudo cp monoset-enhanced /usr/local/bin/ 2>/dev/null || {
            log_warning "Could not install to /usr/local/bin, copying to $HOME/bin"
            mkdir -p "$HOME/bin"
            cp monoset-enhanced "$HOME/bin/"
        }
        sudo chmod +x /usr/local/bin/monoset-enhanced 2>/dev/null || chmod +x "$HOME/bin/monoset-enhanced"
        log_success "Enhanced utilities installed"
    fi
}

# Configure system (only for Raspberry Pi)
configure_system() {
    log_info "Configuring system..."
    
    # Detect if this is a Raspberry Pi
    if [ ! -f "/boot/config.txt" ] && [ ! -f "/boot/firmware/config.txt" ]; then
        log_warning "Not a Raspberry Pi system - skipping boot configuration"
        log_info "Manual configuration may be required for your system"
        return 0
    fi
    
    # Check if configuration is already present
    local config_file="/boot/config.txt"
    if [ -f "/boot/firmware/config.txt" ]; then
        config_file="/boot/firmware/config.txt"
    fi
    
    if ! grep -q "dtoverlay=sharp-drm-enhanced" "$config_file" 2>/dev/null; then
        log_info "Adding device tree overlay to $config_file"
        echo "" | sudo tee -a "$config_file" >/dev/null
        echo "# Sharp DRM Enhanced Driver" | sudo tee -a "$config_file" >/dev/null
        echo "dtparam=spi=on" | sudo tee -a "$config_file" >/dev/null
        echo "dtoverlay=sharp-drm-enhanced" | sudo tee -a "$config_file" >/dev/null
    else
        log_info "Configuration already present in $config_file"
    fi
    
    # Configure kernel command line
    local cmdline_file="/boot/cmdline.txt"
    if [ -f "/boot/firmware/cmdline.txt" ]; then
        cmdline_file="/boot/firmware/cmdline.txt"
    fi
    
    if [ -f "$cmdline_file" ] && ! grep -q "console=tty2" "$cmdline_file" 2>/dev/null; then
        log_info "Configuring framebuffer console"
        sudo cp "$cmdline_file" "${cmdline_file}.backup" 2>/dev/null || true
        sudo sed -i 's/$/ console=tty2 fbcon=font:VGA8x8 fbcon=map:10/' "$cmdline_file" 2>/dev/null || {
            log_warning "Could not modify $cmdline_file - manual configuration may be needed"
        }
    fi
    
    # Add module to auto-load
    if ! grep -q "sharp-drm-enhanced" /etc/modules 2>/dev/null; then
        echo "sharp-drm-enhanced" | sudo tee -a /etc/modules >/dev/null 2>&1 || {
            log_warning "Could not add module to /etc/modules - manual configuration may be needed"
        }
    fi
    
    log_success "System configured"
}

# Run tests
run_tests() {
    log_info "Running basic tests..."
    
    # Test compilation
    cd "$SCRIPT_DIR"
    if make test 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Compilation test passed"
    else
        log_warning "Compilation test failed - check $LOG_FILE"
    fi
    
    # Test device tree compilation
    if [ -f "sharp-drm-enhanced.dtbo" ]; then
        log_success "Device tree overlay compiled successfully"
    else
        log_warning "Device tree overlay not found"
    fi
    
    # Check if module loads (basic test)
    if [ -f "sharp-drm-enhanced.ko" ]; then
        log_success "Kernel module created successfully"
        
        # Try to get module info
        if modinfo ./sharp-drm-enhanced.ko >/dev/null 2>&1; then
            log_success "Module structure is valid"
        else
            log_warning "Module may have issues - check with: modinfo ./sharp-drm-enhanced.ko"
        fi
    else
        log_warning "Kernel module not found"
    fi
}

# Show installation summary
show_summary() {
    log_info "Installation Summary"
    echo "===================="
    echo "Driver: Sharp DRM Enhanced v2.0"
    echo "Location: $(pwd)"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Files created:"
    [ -f "sharp-drm-enhanced.ko" ] && echo "  ✓ Kernel module: sharp-drm-enhanced.ko"
    [ -f "sharp-drm-enhanced.dtbo" ] && echo "  ✓ Device tree overlay: sharp-drm-enhanced.dtbo"
    [ -f "/usr/local/bin/monoset-enhanced" ] || [ -f "$HOME/bin/monoset-enhanced" ] && echo "  ✓ Enhanced utilities installed"
    echo ""
    echo "Next steps:"
    echo "1. Reboot your system: sudo reboot (if on Raspberry Pi)"
    echo "2. Load the module: sudo modprobe sharp-drm-enhanced"
    echo "3. Check driver status: lsmod | grep sharp"
    echo "4. Test display: monoset-enhanced --status"
    echo ""
    echo "For help and troubleshooting, see README.md"
}

# Main installation function
main() {
    log_info "Sharp DRM Enhanced Driver Installation v2.0"
    log_info "============================================="
    
    check_root
    check_prerequisites
    backup_original
    build_driver
    run_tests
    install_driver
    configure_system
    show_summary
    
    log_success "Installation completed successfully!"
    
    # Check if this looks like a Raspberry Pi
    if [ -f "/boot/config.txt" ] || [ -f "/boot/firmware/config.txt" ]; then
        log_warning "Please reboot your system to load the new driver."
    else
        log_info "Load the driver manually with: sudo modprobe sharp-drm-enhanced"
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Sharp DRM Enhanced Driver Installation Script"
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --build-only   Only build the driver, don't install"
        echo "  --test-only    Only run tests"
        echo ""
        exit 0
        ;;
    --build-only)
        check_prerequisites
        build_driver
        run_tests
        log_success "Build completed. Use 'sudo make install' to install."
        ;;
    --test-only)
        run_tests
        ;;
    *)
        main
        ;;
esac
