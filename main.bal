import ballerina/http;
import ballerina/log;
import ballerina/os;
import ballerinax/redis;

configurable string redisHost = "redis-99131fcf-9c25-444d-b667-32595703bbb0-redissv2014260135-ch.e.aivencloud.com";
configurable int redisPort = 22930;
configurable string redisPassword = os:getEnv("REDIS_PASS");

configurable string awsRedisHost = "redis-99131fcf-9c25-444d-b667-32595703bbb0-redissv2316697524-ch.l.aivencloud.com";
configurable int awsRedisPort = 22930;
configurable string awsRedisPassword = os:getEnv("AWS_REDIS_PASS");

redis:SecureSocket redisSecureSocket = {
    verifyMode: redis:FULL
};

redis:ConnectionConfig redisConfig = {
    connection: {
        host: redisHost,
        port: redisPort,
        password: redisPassword,
        options: {
            connectionTimeout: 5
        }
    },
    connectionPooling: true,
    secureSocket: redisSecureSocket
};

redis:ConnectionConfig awsRedisConfig = {
    connection: {
        host: awsRedisHost,
        port: awsRedisPort,
        password: awsRedisPassword,
        options: {
            connectionTimeout: 5
        }
    },
    connectionPooling: true,
    secureSocket: redisSecureSocket
};

redis:Client redisClient = check new (redisConfig);
redis:Client awsRedisClient = check new (awsRedisConfig);

listener http:Listener httpListener = check new (2020);

service / on httpListener {
    resource function get cache\-item() returns http:Ok|http:InternalServerError {
        string message = "Hello, World!";
        string?|error cachedMessage = redisClient->get("hello");
        if cachedMessage is error {
            log:printError("Error getting cache key", cachedMessage);
        } else if cachedMessage is () {
            log:printInfo("Cache miss");
            string|error? setError = redisClient->set("hello", "Hello, World!, Cached");
            if setError is error {
                log:printError("Error setting cache key", setError);
            }
        } else {
            message = <string>cachedMessage;
            log:printInfo("Cache hit");
        }
        return <http:Ok>{
            body: message
        };
    }

    resource function get aws\-cache\-item() returns http:Ok|http:InternalServerError {
        string message = "Hello, World!";
        string?|error cachedMessage = awsRedisClient->get("hello");
        if cachedMessage is error {
            log:printError("Error getting cache key from AWS Redis", cachedMessage);
        } else if cachedMessage is () {
            log:printInfo("AWS Redis cache miss");
            string|error? setError = awsRedisClient->set("hello", "Hello, World!, Cached from AWS");
            if setError is error {
                log:printError("Error setting AWS Redis cache key", setError);
            }
        } else {
            message = <string>cachedMessage;
            log:printInfo("AWS Redis cache hit");
        }
        return <http:Ok>{
            body: message
        };
    }

    resource function post clear\-cache() returns http:Ok|http:InternalServerError {
        int|error? deleteError = redisClient->del(["hello"]);
        if deleteError is error {
            log:printError("Error deleting cache key", deleteError);
        } else {
            log:printInfo("Cache key deleted successfully");
        }
        return <http:Ok>{
            body: "Cache cleared"
        };
    }

    resource function post aws\-clear\-cache() returns http:Ok|http:InternalServerError {
        int|error? deleteError = awsRedisClient->del(["hello"]);
        if deleteError is error {
            log:printError("Error deleting AWS Redis cache key", deleteError);
        } else {
            log:printInfo("AWS Redis cache key deleted successfully");
        }
        return <http:Ok>{
            body: "AWS Redis cache cleared"
        };
    }
}
