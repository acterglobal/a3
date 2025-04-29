// These are dart extensions we add to the generated ffi bindings after
// processing.

extension AddressClientExtension on Client {
  int get address => _box.borrow();
}
