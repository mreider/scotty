#!/usr/bin/env ruby
#

require 'set'

class GolangStdLib
  
  @@package_list = %w(
    archive
    archive/tar
    archive/zip
    bufio
    builtin
    bytes
    compress
    compress/bzip2
    compress/flate
    compress/gzip
    compress/lzw
    compress/zlib
    container
    container/heap
    container/list
    container/ring
    crypto
    crypto/aes
    crypto/cipher
    crypto/des
    crypto/dsa
    crypto/ecdsa
    crypto/elliptic
    crypto/hmac
    crypto/md5
    crypto/rand
    crypto/rc4
    crypto/rsa
    crypto/sha1
    crypto/sha256
    crypto/sha512
    crypto/subtle
    crypto/tls
    crypto/x509
    crypto/x509/pkix
    database
    database/sql
    database/sql/driver
    debug
    debug/dwarf
    debug/elf
    debug/gosym
    debug/macho
    debug/pe
    encoding
    encoding/ascii85
    encoding/asn1
    encoding/base32
    encoding/base64
    encoding/binary
    encoding/csv
    encoding/gob
    encoding/hex
    encoding/json
    encoding/pem
    encoding/xml
    errors
    expvar
    flag
    fmt
    go
    go/ast
    go/build
    go/doc
    go/parser
    go/printer
    go/scanner
    go/token
    hash
    hash/adler32
    hash/crc32
    hash/crc64
    hash/fnv
    html
    html/template
    image
    image/color
    image/draw
    image/gif
    image/jpeg
    image/png
    index
    index/suffixarray
    io
    io/ioutil
    log
    log/syslog
    math
    math/big
    math/cmplx
    math/rand
    mime
    mime/multipart
    net
    net/http
    net/http/cgi
    net/http/fcgi
    net/http/httptest
    net/http/httputil
    net/http/pprof
    net/mail
    net/rpc
    net/rpc/jsonrpc
    net/smtp
    net/textproto
    net/url
    os
    os/exec
    os/signal
    os/user
    path
    path/filepath
    reflect
    regexp
    regexp/syntax
    runtime
    runtime/cgo
    runtime/debug
    runtime/pprof
    sort
    strconv
    strings
    sync
    sync/atomic
    syscall
    testing
    testing/iotest
    testing/quick
    text
    text/scanner
    text/tabwriter
    text/template
    text/template/parse
    time
    unicode
    unicode/utf16
    unicode/utf8
    unsafe)
    
  @@packages = @@package_list.to_set
  
  def self.each
    @@packages.dup.each { |p| yield p }
  end
  
  def self.remove_standard_packages(packages)
    packages.reject { |p| @@packages.include? p }
  end
  
  def self.include?(package)
    @@packages.include? package
  end
  
  private

end
