// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/// A `Schema` object allows the definition of input and output data types.
///
/// These types can be objects, but also primitives and arrays. Represents a select subset of an
/// [OpenAPI 3.0 schema object](https://spec.openapis.org/oas/v3.0.3#schema).
@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
public final class Schema: Sendable {
  /// Modifiers describing the expected format of a string `Schema`.
  @available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
  public struct StringFormat: EncodableProtoEnum {
    // This enum is currently only used to conform `StringFormat` to `ProtoEnum`, which requires
    // `associatedtype Kind: RawRepresentable<String>`.
    enum Kind: String {
      // Providing a case resolves the error "An enum with no cases cannot declare a raw type".
      case unused // TODO: Remove `unused` case when we have at least one specific string format.
    }

    /// A custom string format.
    public static func custom(_ format: String) -> StringFormat {
      return self.init(rawValue: format)
    }

    let rawValue: String
  }

  /// Modifiers describing the expected format of an integer `Schema`.
  @available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
  public struct IntegerFormat: EncodableProtoEnum, Sendable {
    enum Kind: String {
      case int32
      case int64
    }

    /// A 32-bit signed integer.
    public static let int32 = IntegerFormat(kind: .int32)

    /// A 64-bit signed integer.
    public static let int64 = IntegerFormat(kind: .int64)

    /// A custom integer format.
    public static func custom(_ format: String) -> IntegerFormat {
      return self.init(rawValue: format)
    }

    let rawValue: String
  }

  let dataType: DataType

  /// The data type.
  public var type: String { dataType.rawValue }

  /// The format of the data.
  public let format: String?

  /// A brief description of the parameter.
  public let description: String?

  /// Indicates if the value may be null.
  public let nullable: Bool?

  /// Possible values of the element of type "STRING" with "enum" format.
  public let enumValues: [String]?

  /// Schema of the elements of type `"ARRAY"`.
  public let items: Schema?

  /// The minimum number of items (elements) in a schema of type `"ARRAY"`.
  public let minItems: Int?

  /// The maximum number of items (elements) in a schema of type `"ARRAY"`.
  public let maxItems: Int?

  /// Properties of type `"OBJECT"`.
  public let properties: [String: Schema]?

  /// Required properties of type `"OBJECT"`.
  public let requiredProperties: [String]?

  required init(type: DataType, format: String? = nil, description: String? = nil,
                nullable: Bool = false, enumValues: [String]? = nil, items: Schema? = nil,
                minItems: Int? = nil, maxItems: Int? = nil,
                properties: [String: Schema]? = nil, requiredProperties: [String]? = nil) {
    dataType = type
    self.format = format
    self.description = description
    self.nullable = nullable
    self.enumValues = enumValues
    self.items = items
    self.minItems = minItems
    self.maxItems = maxItems
    self.properties = properties
    self.requiredProperties = requiredProperties
  }

  /// Returns a `Schema` representing a string value.
  ///
  /// This schema instructs the model to produce data of type `"STRING"`, which is suitable for
  /// decoding into a Swift `String` (or `String?`, if `nullable` is set to `true`).
  ///
  /// > Tip: If a specific set of string values should be generated by the model (for example,
  /// > "north", "south", "east", or "west"), use ``enumeration(values:description:nullable:)``
  /// > instead to constrain the generated values.
  ///
  /// - Parameters:
  ///   - description: An optional description of what the string should contain or represent; may
  ///     use Markdown format.
  ///   - nullable: If `true`, instructs the model that it *may* generate `null` instead of a
  ///     string; defaults to `false`, enforcing that a string value is generated.
  ///   - format: An optional modifier describing the expected format of the string. Currently no
  ///     formats are officially supported for strings but custom values may be specified using
  ///     ``StringFormat/custom(_:)``, for example `.custom("email")` or `.custom("byte")`; these
  ///     provide additional hints for how the model should respond but are not guaranteed to be
  ///     adhered to.
  public static func string(description: String? = nil, nullable: Bool = false,
                            format: StringFormat? = nil) -> Schema {
    return self.init(
      type: .string,
      format: format?.rawValue,
      description: description,
      nullable: nullable
    )
  }

  /// Returns a `Schema` representing an enumeration of string values.
  ///
  /// This schema instructs the model to produce data of type `"STRING"` with the `format` `"enum"`.
  /// This data is suitable for decoding into a Swift `String` (or `String?`, if `nullable` is set
  /// to `true`), or an `enum` with strings as raw values.
  ///
  /// **Example:**
  /// The values `["north", "south", "east", "west"]` for an enumeration of directions.
  /// ```
  /// enum Direction: String, Decodable {
  ///   case north, south, east, west
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - values: The list of string values that may be generated by the model.
  ///   - description: An optional description of what the `values` contain or represent; may use
  ///     Markdown format.
  ///   - nullable: If `true`, instructs the model that it *may* generate `null` instead of one of
  ///     the strings specified in `values`; defaults to `false`, enforcing that one of the string
  ///     values is generated.
  public static func enumeration(values: [String], description: String? = nil,
                                 nullable: Bool = false) -> Schema {
    return self.init(
      type: .string,
      format: "enum",
      description: description,
      nullable: nullable,
      enumValues: values
    )
  }

  /// Returns a `Schema` representing a single-precision floating-point number.
  ///
  /// This schema instructs the model to produce data of type `"NUMBER"` with the `format`
  /// `"float"`, which is suitable for decoding into a Swift `Float` (or `Float?`, if `nullable` is
  /// set to `true`).
  ///
  /// > Important: This `Schema` provides a hint to the model that it should generate a
  /// > single-precision floating-point number, a `float`, but only guarantees that the value will
  /// > be a number.
  ///
  /// - Parameters:
  ///   - description: An optional description of what the number should contain or represent; may
  ///     use Markdown format.
  ///   - nullable: If `true`, instructs the model that it may generate `null` instead of a number;
  ///     defaults to `false`, enforcing that a number is generated.
  public static func float(description: String? = nil, nullable: Bool = false) -> Schema {
    return self.init(
      type: .number,
      format: "float",
      description: description,
      nullable: nullable
    )
  }

  /// Returns a `Schema` representing a floating-point number.
  ///
  /// This schema instructs the model to produce data of type `"NUMBER"`, which is suitable for
  /// decoding into a Swift `Double` (or `Double?`, if `nullable` is set to `true`).
  ///
  /// - Parameters:
  ///   - description: An optional description of what the number should contain or represent; may
  ///     use Markdown format.
  ///   - nullable: If `true`, instructs the model that it may return `null` instead of a number;
  ///     defaults to `false`, enforcing that a number is returned.
  public static func double(description: String? = nil, nullable: Bool = false) -> Schema {
    return self.init(
      type: .number,
      description: description,
      nullable: nullable
    )
  }

  /// Returns a `Schema` representing an integer value.
  ///
  /// This schema instructs the model to produce data of type `"INTEGER"`, which is suitable for
  /// decoding into a Swift `Int` (or `Int?`, if `nullable` is set to `true`) or other integer types
  /// (such as `Int32`) based on the expected size of values being generated.
  ///
  /// > Important: If a `format` of ``IntegerFormat/int32`` or ``IntegerFormat/int64`` is
  /// > specified, this provides a hint to the model that it should generate 32-bit or 64-bit
  /// > integers but this `Schema` only guarantees that the value will be an integer. Therefore, it
  /// > is *possible* that decoding into an `Int32` could overflow even if a `format` of
  /// > ``IntegerFormat/int32`` is specified.
  ///
  /// - Parameters:
  ///   - description: An optional description of what the integer should contain or represent; may
  ///     use Markdown format.
  ///   - nullable: If `true`, instructs the model that it may return `null` instead of an integer;
  ///     defaults to `false`, enforcing that an integer is returned.
  ///   - format: An optional modifier describing the expected format of the integer. Currently the
  ///     formats ``IntegerFormat/int32`` and ``IntegerFormat/int64`` are supported; custom values
  ///     may be specified using ``IntegerFormat/custom(_:)`` but may be ignored by the model.
  public static func integer(description: String? = nil, nullable: Bool = false,
                             format: IntegerFormat? = nil) -> Schema {
    return self.init(
      type: .integer,
      format: format?.rawValue,
      description: description,
      nullable: nullable
    )
  }

  /// Returns a `Schema` representing a boolean value.
  ///
  /// This schema instructs the model to produce data of type `"BOOLEAN"`, which is suitable for
  /// decoding into a Swift `Bool` (or `Bool?`, if `nullable` is set to `true`).
  ///
  /// - Parameters:
  ///   - description: An optional description of what the boolean should contain or represent; may
  ///   use Markdown format.
  ///   - nullable: If `true`, instructs the model that it may return `null` instead of a boolean;
  ///   defaults to `false`, enforcing that a boolean is returned.
  public static func boolean(description: String? = nil, nullable: Bool = false) -> Schema {
    return self.init(type: .boolean, description: description, nullable: nullable)
  }

  /// Returns a `Schema` representing an array.
  ///
  /// This schema instructs the model to produce data of type `"ARRAY"`, which has elements of any
  /// other data type (including nested `"ARRAY"`s). This data is suitable for decoding into many
  /// Swift collection types, including `Array`, holding elements of types suitable for decoding
  /// from the respective `items` type.
  ///
  /// - Parameters:
  ///   - items: The `Schema` of the elements that the array will hold.
  ///   - description: An optional description of what the array should contain or represent; may
  ///     use Markdown format.
  ///   - nullable: If `true`, instructs the model that it may return `null` instead of an array;
  ///     defaults to `false`, enforcing that an array is returned.
  ///   - minItems: Instructs the model to produce at least the specified minimum number of elements
  ///     in the array; defaults to `nil`, meaning any number.
  ///   - maxItems: Instructs the model to produce at most the specified maximum number of elements
  ///     in the array.
  public static func array(items: Schema, description: String? = nil, nullable: Bool = false,
                           minItems: Int? = nil, maxItems: Int? = nil) -> Schema {
    return self.init(
      type: .array,
      description: description,
      nullable: nullable,
      items: items,
      minItems: minItems,
      maxItems: maxItems
    )
  }

  /// Returns a `Schema` representing an object.
  ///
  /// This schema instructs the model to produce data of type `"OBJECT"`, which has keys of type
  /// `"STRING"` and values of any other data type (including nested `"OBJECT"`s). This data is
  /// suitable for decoding into Swift keyed collection types, including `Dictionary`, or other
  /// custom `struct` or `class` types.
  ///
  /// **Example:** A `City` could be represented with the following object `Schema`.
  /// ```
  /// Schema.object(properties: [
  ///   "name" : .string(),
  ///   "population": .integer()
  /// ])
  /// ```
  /// The generated data could be decoded into a Swift native type:
  /// ```
  /// struct City: Decodable {
  ///   let name: String
  ///   let population: Int
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - properties: A dictionary containing the object's property names as keys and their
  ///   respective `Schema`s as values.
  ///   - optionalProperties: A list of property names that may be be omitted in objects generated
  ///   by the model; these names must correspond to the keys provided in the `properties`
  ///   dictionary and may be an empty list.
  ///   - description: An optional description of what the object should contain or represent; may
  ///   use Markdown format.
  ///   - nullable: If `true`, instructs the model that it may return `null` instead of an object;
  ///   defaults to `false`, enforcing that an object is returned.
  public static func object(properties: [String: Schema], optionalProperties: [String] = [],
                            description: String? = nil, nullable: Bool = false) -> Schema {
    var requiredProperties = Set(properties.keys)
    for optionalProperty in optionalProperties {
      guard properties.keys.contains(optionalProperty) else {
        fatalError("Optional property \"\(optionalProperty)\" not defined in object properties.")
      }
      requiredProperties.remove(optionalProperty)
    }

    return self.init(
      type: .object,
      description: description,
      nullable: nullable,
      properties: properties,
      requiredProperties: requiredProperties.sorted()
    )
  }
}

// MARK: - Codable Conformance

@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
extension Schema: Encodable {
  enum CodingKeys: String, CodingKey {
    case dataType = "type"
    case format
    case description
    case nullable
    case enumValues = "enum"
    case items
    case minItems
    case maxItems
    case properties
    case requiredProperties = "required"
  }
}
