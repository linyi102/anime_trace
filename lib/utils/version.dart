String formatVersion(String? version) => version == null
    ? ''
    : version.startsWith('v')
        ? version.substring(1)
        : version;
