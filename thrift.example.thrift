/**
 * Example Thrift IDL demonstrating various features and schema evolution patterns
 * @version 2.1
 * @since 1.0
 */

// Namespace declarations for different languages
namespace go weather
namespace js weather
namespace py weather

/**
 * Basic types demonstration:
 * bool    - Boolean value
 * i32     - 32-bit integer
 * i64     - 64-bit integer
 * double  - Double precision float
 * string  - String
 * binary  - Byte array
 */

/**
 * Example of an enumeration
 * - Enums are specified C-style
 * - Compiler assigns default values starting at 0
 * - You can supply specific integral values
 * - Hex values are acceptable
 */
enum WeatherCondition {
    SUNNY = 1,
    CLOUDY = 2,
    RAINY = 3,
    STORMY = 0xa,    // Hex values are valid
    SNOWY            // Auto-assigned to 11
}

/**
 * Version 1: Original struct
 * Field numbers are critical - they are the contract between clients and servers
 * Never change existing field numbers
 */
struct WeatherResponseV1 {
    1: required string location,        // Never change this field number
    2: required double temperature,     // Never change this field number
    3: required string unit            // Never change this field number
}

/**
 * Version 2: Evolution with new fields
 * When adding new fields:
 * 1. Make them optional
 * 2. Use new field numbers
 * 3. Provide default values
 */
struct WeatherResponseV2 {
    1: required string location,
    2: required double temperature,
    3: required string unit,
    4: optional double humidity = 0.0,         // New optional field
    5: optional WeatherCondition condition = WeatherCondition.SUNNY,   // New optional field with default
    6: optional map<string, string> metadata = {},  // New optional complex field
}

/**
 * Version 3: Deprecating fields
 * Never delete fields directly. Instead:
 * 1. Mark them as deprecated in comments
 * 2. Make them optional
 * 3. Consider renaming with 'DEPRECATED_' prefix
 */
struct WeatherResponseV3 {
    1: required string location,
    2: required double temperature,
    3: required string unit,
    // @deprecated - Use condition field instead (since v2.1)
    4: optional double humidity,
    5: optional WeatherCondition condition = WeatherCondition.SUNNY,
    6: optional map<string, string> metadata = {},
    7: optional list<string> DEPRECATED_old_conditions,  // Clear deprecation signal
    8: optional i32 api_version = 3
}

/**
 * Example of safe type evolution
 * Safe changes include:
 * - i32 to i64 (widening)
 * - Adding optional fields
 * - Adding new structs
 */
struct UserProfile {
    1: required i64 id,        // Safe: was i32 in v1
    2: required string name,
    3: optional list<string> tags = []  // Safe: new optional field
}

/**
 * Example of a request struct showing required vs optional fields
 * Use required for:
 * - Primary keys
 * - Essential business logic fields
 * - Fields that must be validated
 */
struct WeatherRequest {
    1: required string location,     // Location is essential
    2: optional string language = "en",  // Language can have default
    3: optional i32 timeout_ms = 1000    // Optional with default
}

/**
 * Example of error handling with exceptions
 */
exception WeatherServiceError {
    1: required string message,
    2: required i32 error_code,
    3: optional string details
}

/**
 * Example of versioning using a wrapper struct
 */
union WeatherResponse {
    1: WeatherResponseV1 v1,
    2: WeatherResponseV2 v2,
    3: WeatherResponseV3 v3
}

/**
 * Constants definition example
 */
const i32 DEFAULT_TIMEOUT_MS = 5000
const string API_VERSION = "2.1.0"
const map<string, string> DEFAULT_HEADERS = {
    "User-Agent": "ThriftWeatherClient/2.1",
    "Accept-Language": "en-US"
}

/**
 * Service definition showing:
 * - Multiple versions of methods
 * - Error handling
 * - Different parameter types
 */
service WeatherService {
    // Current version
    WeatherResponse getWeather(
        1: required WeatherRequest request
    ) throws (
        1: WeatherServiceError error
    )

    // Legacy support, marked for deprecation
    // @deprecated: Use getWeather instead
    WeatherResponseV1 getWeatherV1(
        1: required string location
    )

    // Streaming example
    oneway void subscribeToWeatherUpdates(
        1: required string location,
        2: optional i32 update_interval_ms = 1000
    )

    // Batch operation example
    list<WeatherResponse> batchGetWeather(
        1: required list<string> locations,
        2: optional map<string, string> options
    ) throws (
        1: WeatherServiceError error
    )
}

/**
 * Alternative Versioning Strategy 1: Using Struct Versioning
 * This approach maintains separate structs for each version
 * and uses a wrapper struct to handle all versions
 */
struct DataV1 {
    1: required string field1
}

struct DataV2 {
    1: required string field1,
    2: optional string field2
}

struct Data {
    1: optional DataV1 v1,
    2: optional DataV2 v2
}

/**
 * Alternative Versioning Strategy 2: Using Optional Fields
 * This approach uses feature flags to control functionality
 * across different versions
 */
struct FeatureFlags {
    1: optional bool legacy_feature = true,      // Original
    2: optional bool beta_feature = false,       // Added in v2
    3: optional bool experimental = false        // Added in v3
}

/**
 * Forward Compatibility Example
 * Shows how to add new fields while maintaining
 * compatibility with older clients
 */
struct Message {
    1: required string content,
    2: optional map<string, string> metadata = {},  // New clients can use this
    3: optional i32 version = 1                    // Version tracking
}

/**
 * Backward Compatibility Example
 * Shows how to handle removed functionality while
 * maintaining compatibility with older clients
 */
struct ApiResponse {
    1: required string data,
    // @deprecated - Removed in v2, kept for backward compatibility
    2: optional string legacy_field,
    3: optional string new_field = "default"  // Replacement for legacy_field
}

/**
 * Base Response incorporating version tracking
 * All responses should extend this base structure
 */
struct BaseResponse {
    1: required bool success,
    2: optional string error_message,
    3: optional string api_version = API_VERSION
}

/**
 * Extended Weather Service showing migration support
 * and versioning best practices
 */
service ExtendedWeatherService {
    // Current version with full features
    BaseResponse getWeather(
        1: required WeatherRequest request,
        2: optional FeatureFlags features
    ) throws (
        1: WeatherServiceError error
    ),
    
    // Legacy support, marked for deprecation
    // @deprecated: Use getWeather instead
    BaseResponse getWeatherV1(
        1: required string location
    ) throws (
        1: WeatherServiceError error
    ),
    
    // Beta features with version tracking
    Message getWeatherBeta(
        1: required WeatherRequest request,
        2: optional map<string, string> metadata
    ) throws (
        1: WeatherServiceError error
    ),
    
    // Example of handling removed functionality
    // @deprecated: Use getWeather with features.legacy_feature=true instead
    ApiResponse getLegacyWeather(
        1: required string location
    ),
    
    // Version-aware batch operation
    list<BaseResponse> batchGetWeather(
        1: required list<WeatherRequest> requests,
        2: optional FeatureFlags features,
        3: optional Data compatData              // For version compatibility
    ) throws (
        1: WeatherServiceError error
    )
}

/**
 * Example of a fully documented response structure
 * showing best practices for documentation
 */
struct DetailedWeatherResponse extends BaseResponse {
    /**
     * Represents detailed weather conditions
     * @version 2.1
     * @since 1.0
     * @deprecated fields: humidity (use condition instead)
     *                    old_format (use new_format instead)
     */
    1: required string location,
    2: required double temperature,
    3: required string unit,
    
    // @deprecated - Use condition field instead (since v2.1)
    4: optional double humidity,
    
    // Current recommended fields
    5: optional WeatherCondition condition = WeatherCondition.SUNNY,
    6: optional map<string, string> metadata = {},
    
    // Feature flag controlled fields
    7: optional FeatureFlags features,
    
    // Version compatibility fields
    8: optional Data compatData,
    
    // Migration support
    9: optional string DEPRECATED_old_format,
    10: optional string new_format = "standard"
}
