namespace LocationService.Application.Common;

public class ServiceResult<T>
{
    public bool Success { get; private set; }
    public T? Data { get; private set; }
    public string? Error { get; private set; }
    public int StatusCode { get; private set; }

    public static ServiceResult<T> Ok(T data) =>
        new() { Success = true, Data = data, StatusCode = 200 };

    public static ServiceResult<T> NotFound(string error) =>
        new() { Success = false, Error = error, StatusCode = 404 };

    public static ServiceResult<T> Fail(string error) =>
        new() { Success = false, Error = error, StatusCode = 400 };

    public static ServiceResult<T> Forbidden(string error) =>
        new() { Success = false, Error = error, StatusCode = 403 };
}
