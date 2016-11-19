//
//  CStringArray.swift
//  VimIOS
//
// d.
// from https://gist.github.com/neilpa/b430d148d1c5f4ae5ddd

class CString {
    fileprivate let _len: Int
    let buffer: UnsafeMutablePointer<Int8>
    
    init(_ string: String) {
        (_len, buffer) = string.withCString {
            let len = Int(strlen($0) + 1)
            let dst = strcpy(UnsafeMutablePointer<Int8>.allocate(capacity: len), $0)
            return (len, dst!)
        }
    }
    
    deinit {
        buffer.deallocate(capacity: _len)
    }
}

//// An array of C-style strings (e.g. char**) for easier interop.
//class CStringArray {
//    // Have to keep the owning CString's alive so that the pointers
//    // in our buffer aren't dealloc'd out from under us.
//    fileprivate let _strings: [CString]
//    var pointers: [UnsafeMutablePointer<Int8>]
//    
//    init(_ strings: [String]) {
//        _strings = strings.map { CString($0) }
//        pointers = _strings.map { $0.buffer }
//        // NULL-terminate our string pointer buffer since things like
//        // exec*() and posix_spawn() require this.
//        pointers.append(nil)
//    }
//}
