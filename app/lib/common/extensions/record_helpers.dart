/// AllHashed is a helper for record-types to ensure they are cached
/// properly by riverpod.
///
/// When giving a record e.g. `typedef query = ({String roomIdOrAlias, List<String> serverNames});`
/// as the parameter to a riverpod provider, the latter `List<String>` will
/// have different hashes for every instance created. This means that even if
/// both are `List.empty()` riverpod doesn't recognise them as the same and will
/// run the provider again, cluttering up memory as well as unnecessary computation
///
/// This type, given a list of items `T` will always return the same hash for the
/// same items.
class AllHashed<T> {
  final List<T> items;

  AllHashed(this.items);

  @override
  int get hashCode => Object.hashAll(items);

  @override
  bool operator ==(Object other) {
    if (other is AllHashed<T>) {
      return items == other.items;
    } else if (other is List<T>) {
      return items == other;
    }
    return false;
  }
}
