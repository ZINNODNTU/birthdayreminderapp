/// Simple semantic version parser and comparator.
class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion(this.major, this.minor, this.patch, [this.build = 0]);

  final int major;
  final int minor;
  final int patch;
  final int build;

  /// Parse a version string like "1.2.3" or "1.2.3+4".
  /// Returns null if parsing fails.
  static SemanticVersion? parse(String version) {
    final parts = version.split('+');
    final sem = parts[0].split('.').map(int.tryParse).toList();
    if (sem.length != 3 || sem.any((e) => e == null)) return null;
    final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return SemanticVersion(sem[0]!, sem[1]!, sem[2]!, build);
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    return build.compareTo(other.build);
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  @override
  String toString() =>
      build > 0 ? '$major.$minor.$patch+$build' : '$major.$minor.$patch';
}
