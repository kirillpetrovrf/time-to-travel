enum PermissionType {
  accessLocation,
}

class PermissionManager {
  void tryToRequest(List<PermissionType> permissions) {
    print('🔐 Permission request: $permissions');
  }

  void showRequestDialog(List<PermissionType> permissions) {
    print('🔐 Show permission dialog: $permissions');
  }
}