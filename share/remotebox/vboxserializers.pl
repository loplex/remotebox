# Serializers for missing datatypes in vboxService.pm
use strict;
use warnings;

sub SOAP::Serializer::as_APICMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:APICMode', %$attr}, $value];
}

sub SOAP::Serializer::as_AccessMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:AccessMode', %$attr}, $value];
}

sub SOAP::Serializer::as_AdditionsFacilityType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:AdditionsFacilityType', %$attr}, $value];
}

sub SOAP::Serializer::as_AdditionsRunLevelType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:AdditionsRunLevelType', %$attr}, $value];
}

sub SOAP::Serializer::as_AdditionsUpdateFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:AdditionsUpdateFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_AudioCodecType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:AudioCodecType', %$attr}, $value];
}

sub SOAP::Serializer::as_AudioControllerType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:AudioControllerType', %$attr}, $value];
}

sub SOAP::Serializer::as_AudioDriverType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:AudioDriverType', %$attr}, $value];
}

sub SOAP::Serializer::as_AuthType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:AuthType', %$attr}, $value];
}

sub SOAP::Serializer::as_AutostopType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:AutostopType', %$attr}, $value];
}

sub SOAP::Serializer::as_BIOSBootMenuMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:BIOSBootMenuMode', %$attr}, $value];
}

sub SOAP::Serializer::as_BandwidthGroupType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:BandwidthGroupType', %$attr}, $value];
}

sub SOAP::Serializer::as_BitmapFormat {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:BitmapFormat', %$attr}, $value];
}

sub SOAP::Serializer::as_CPUPropertyType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:CPUPropertyType', %$attr}, $value];
}

sub SOAP::Serializer::as_ChipsetType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ChipsetType', %$attr}, $value];
}

sub SOAP::Serializer::as_CleanupMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:CleanupMode', %$attr}, $value];
}

sub SOAP::Serializer::as_ClipboardMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ClipboardMode', %$attr}, $value];
}

sub SOAP::Serializer::as_CloneMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:CloneMode', %$attr}, $value];
}

sub SOAP::Serializer::as_CloneOptions {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:CloneOptions', %$attr}, $value];
}

sub SOAP::Serializer::as_DeviceType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:DeviceType', %$attr}, $value];
}

sub SOAP::Serializer::as_DhcpOpt {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:DhcpOpt', %$attr}, $value];
}

sub SOAP::Serializer::as_DirectoryCopyFlags {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:DirectoryCopyFlags', %$attr}, $value];
}

sub SOAP::Serializer::as_DirectoryCreateFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:DirectoryCreateFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_DirectoryOpenFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:DirectoryOpenFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_DirectoryRemoveRecFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:DirectoryRemoveRecFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_DnDAction {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:DnDAction', %$attr}, $value];
}

sub SOAP::Serializer::as_DnDMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:DnDMode', %$attr}, $value];
}

sub SOAP::Serializer::as_ExportOptions {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ExportOptions', %$attr}, $value];
}

sub SOAP::Serializer::as_FaultToleranceState {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:FaultToleranceState', %$attr}, $value];
}

sub SOAP::Serializer::as_FileAccessMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:FileAccessMode', %$attr}, $value];
}

sub SOAP::Serializer::as_FileCopyFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:FileCopyFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_FileOpenAction {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:FileOpenAction', %$attr}, $value];
}

sub SOAP::Serializer::as_FileOpenExFlags {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:FileOpenExFlags', %$attr}, $value];
}

sub SOAP::Serializer::as_FileSeekOrigin {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:FileSeekOrigin', %$attr}, $value];
}

sub SOAP::Serializer::as_FileSharingMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:FileSharingMode', %$attr}, $value];
}

sub SOAP::Serializer::as_FirmwareType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:FirmwareType', %$attr}, $value];
}

sub SOAP::Serializer::as_FsObjMoveFlags {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:FsObjMoveFlags', %$attr}, $value];
}

sub SOAP::Serializer::as_FsObjRenameFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:FsObjRenameFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_GraphicsControllerType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:GraphicsControllerType', %$attr}, $value];
}

sub SOAP::Serializer::as_GuestSessionWaitForFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:GuestSessionWaitForFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_HWVirtExPropertyType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:HWVirtExPropertyType', %$attr}, $value];
}

sub SOAP::Serializer::as_HostNetworkInterfaceType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:HostNetworkInterfaceType', %$attr}, $value];
}

sub SOAP::Serializer::as_ImportOptions {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ImportOptions', %$attr}, $value];
}

sub SOAP::Serializer::as_KeyboardHIDType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:KeyboardHIDType', %$attr}, $value];
}

sub SOAP::Serializer::as_LockType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:LockType', %$attr}, $value];
}

sub SOAP::Serializer::as_MediumType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:MediumType', %$attr}, $value];
}

sub SOAP::Serializer::as_MediumVariant {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:MediumVariant', %$attr}, $value];
}

sub SOAP::Serializer::as_NATProtocol {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:NATProtocol', %$attr}, $value];
}

sub SOAP::Serializer::as_NetworkAdapterPromiscModePolicy {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:NetworkAdapterPromiscModePolicy', %$attr}, $value];
}

sub SOAP::Serializer::as_NetworkAdapterType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:NetworkAdapterType', %$attr}, $value];
}

sub SOAP::Serializer::as_NetworkAttachmentType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:NetworkAttachmentType', %$attr}, $value];
}

sub SOAP::Serializer::as_ParavirtProvider {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ParavirtProvider', %$attr}, $value];
}

sub SOAP::Serializer::as_PointingHIDType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:PointingHIDType', %$attr}, $value];
}

sub SOAP::Serializer::as_PortMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:PortMode', %$attr}, $value];
}

sub SOAP::Serializer::as_ProcessCreateFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ProcessCreateFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_ProcessInputFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ProcessInputFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_ProcessPriority {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ProcessPriority', %$attr}, $value];
}

sub SOAP::Serializer::as_ProcessWaitForFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ProcessWaitForFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_ProcessorFeature {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ProcessorFeature', %$attr}, $value];
}

sub SOAP::Serializer::as_ScreenLayoutMode {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:ScreenLayoutMode', %$attr}, $value];
}

sub SOAP::Serializer::as_StorageBus {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:StorageBus', %$attr}, $value];
}

sub SOAP::Serializer::as_StorageControllerType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:StorageControllerType', %$attr}, $value];
}

sub SOAP::Serializer::as_SymlinkReadFlag {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:SymlinkReadFlag', %$attr}, $value];
}

sub SOAP::Serializer::as_SymlinkType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:SymlinkType', %$attr}, $value];
}

sub SOAP::Serializer::as_USBControllerType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:USBControllerType', %$attr}, $value];
}

sub SOAP::Serializer::as_USBDeviceFilterAction {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:USBDeviceFilterAction', %$attr}, $value];
}

sub SOAP::Serializer::as_VBoxEventType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:VBoxEventType', %$attr}, $value];
}

sub SOAP::Serializer::as_VirtualSystemDescriptionType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:VirtualSystemDescriptionType', %$attr}, $value];
}

sub SOAP::Serializer::as_VirtualSystemDescriptionValueType {
    my $self = shift;
    my ($value, $name, $type, $attr) = @_;
    return [$name, {'xsi:type' => 'vbox:VirtualSystemDescriptionValueType', %$attr}, $value];
}

1;
