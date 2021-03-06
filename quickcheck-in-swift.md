This afternoon, I've been making my first steps in Swift, trying to see how much of my Haskell knowledge I could port. It seems like a lot of cool stuff you can do with types is not yet possible, I already filed some radars. 

As an experiment, this article is also available as a [playground](/static/quickcheck-in-swift.playground.zip) and on [github](https://github.com/chriseidhof/quickcheck-in-swift-blogpost). Because we'll need the `arc4random` function, we'll start by importing `Foundation`:

```swift
import Foundation
```

I wanted to see if it's possible to implement something like [QuickCheck](http://hackage.haskell.org/package/QuickCheck) in Swift. QuickCheck is a really cool library, available in multiple languages, that allows you to quickly check if properties are false. The interface is simple: you give it a property and it tries to falsify that property. Properties are just simple functions that return `Bool`s. For example, suppose we have a property that checks whether `+` on `Int`s is a commutative operation:

```swift
func prop_plusCommutative(x : Int, y : Int) -> Bool {
    return x + y == y + x
}
```

What we can do is just generate a lot of random numbers, and feed them into this property:

```swift
let numberOfIterations = 100 

for _ in 0..numberOfIterations {
    let valX = Int(arc4random())
    let valY = Int(arc4random())
    assert(prop_plusCommutative(valX,valY))
}
```

Now, if we run this, we'll have this checked a hundred times, with different numbers. It's not a guarantee that it's correct, but it's rather a quick way of checking whether there aren't any obvious mistakes. Suppose we try to write a `reverse` function for strings:



```swift
extension String {
    func reverse() -> String {
        var s = ""
        for char in self {
            s = char + s
        }
        return s
    }
}
```

If we want to check if this is not completely broken, we can take a similar approach:

```swift
func prop_doubleReverse(x : String) -> Bool {
    return x.reverse().reverse() == x
}

func random (#from: Int, #to: Int) -> Int {
    return from + (Int(arc4random()) % to)
}

func randomString() -> String {
  let randomLength = random(from: 0, to: numberOfIterations)
  var string = ""
  for i in 0..randomLength {
      let randomInt : Int = random(from: 13, to: 255)
      string += Character(UnicodeScalar(randomInt))
  }
  return string
}

for _ in 0..numberOfIterations {
    assert(prop_doubleReverse(randomString()))
}
```

Of course, it's not nice to have to rewrite this `0..numberOfIterations` all the time. Instead, we would like to write it like this:

<pre>
check(prop_doubleReverse)
check(prop_plusCommutative)
</pre>

How do we get there? It's actually relatively easy. First, we define the `Arbitrary` protocol, which generates arbitrary values:

```swift
protocol Arbitrary {
    class func arbitrary() -> Self
}
```

Now, we can define an instance for `String` and `Int` (beware, these are just quick and dirty instances):

```swift
extension String : Arbitrary {
    static func arbitrary() -> String {
      return randomString()
    }
}

extension Int : Arbitrary {
    static func arbitrary() -> Int {
        return random(from: 0, to: 10000)
    }
}
```

The only thing left is to define the `check` function. First, we define it for a property that takes a single argument:

```swift
func check<X : Arbitrary>(prop : X -> Bool) -> () {
    for _ in 0..numberOfIterations {
        let val = X.arbitrary()
        assert(prop(val))
    }
}

```

Thanks to overloading, we can also define it for functions that take two arguments:

```swift
func check<X : Arbitrary, Y: Arbitrary>(prop: (X,Y) -> Bool) -> () {
    for _ in 0..numberOfIterations {
        let valX = X.arbitrary()
        let valY = Y.arbitrary()
        assert(prop(valX,valY))
    }
}
```

And that's all there is to it. Now we can check our properties:

```swift
check(prop_doubleReverse)
check(prop_plusCommutative)
```

We can even check closures:

```swift
check({(s : String) -> Bool in countElements(s.reverse()) == countElements(s)})
```

I am really looking forward to people taking this idea and implementing QuickCheck for real. I think it could be a very nice addition to the current way of testing.
