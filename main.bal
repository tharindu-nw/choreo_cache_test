import ballerina/http;
import ballerina/os;
import ballerinax/redis;
import ballerina/log;

configurable string redisHost = "redis-99131fcf-9c25-444d-b667-32595703bbb0-redissv2014260135-ch.e.aivencloud.com";
configurable int redisPort = 22930;
configurable string redisPassword = os:getEnv("REDIS_PASS");

redis:ConnectionConfig redisConfig = {
    connection: {
        host: redisHost,
        port: redisPort,
        password: redisPassword,
        options: {
            connectionTimeout: 5
        }
    },
    connectionPooling: true
};
redis:Client redisClient = check new (redisConfig);

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
}
