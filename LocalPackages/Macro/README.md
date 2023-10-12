# Macro

This package contains **macros** used in the `Pass` project.

## ModifiedCopyMacro
A Swift macro for making inline copies of a struct by modifying a property.<br/>

## Usage

Apply the `@Copyable` macro to a struct:

```swift
@Copyable
struct Person {
    let name: String
    var age: Int
}
```

and it will add a copy function for each stored property and constant:
```swift
struct Person {
    let name: String
    var age: Int

    /// Returns a copy of the caller whose value for `name` is different.
    func copy(name: String) -> Self {
        .init(name: name, age: age)
    }
    
    /// Returns a copy of the caller whose value for `age` is different.
    func copy(age: Int) -> Self {
        .init(name: name, age: age)
    }
}
```

## Capabilities, Limitations and Design Choices

### Chains for multiple changes

To make a copy of a struct and modify multiple properties, you can chain the `copy` calls like this:<br/>
`Person(name: "Walter White", age: 50).copy(age: 52).copy(name: "Heisenberg")`<br/>

### Stored properties and constants

A copy function will be generated for each stored property (`var`) and each constant (`let`) of the struct.<br/>
The macro recognizes computed properties by checking if they have `get` or `set` accessors.<br/>

### Only for struct

This macro works only for structs.<br/>
It doesn't make sense for enums because enums can't have stored properties.<br/>
Classes and actors have reference semantics and we don't want this macro to provide a copy function for reference types.
It is just made to augment the natural copy capability of structs with modified properties.<br/>
This macro emits a Diagnostic Message when you try to apply it to anything but a struct.<br/>
