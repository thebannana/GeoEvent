namespace TicketService.Application.Common;

public class ServiceResult<T>
{
    public bool Success { get; private set; }
    public T? Data { get; private set; }
    public string? Error { get; private set; }
    public int StatusCode { get; private set; }

    public static ServiceResult<T> Ok(T data) =>
        new() { Success = true, Data = data, StatusCode = 200 };

    public static ServiceResult<T> Fail(string error, int statusCode = 400) =>
        new() { Success = false, Error = error, StatusCode = statusCode };

    public static ServiceResult<T> NotFound(string error) =>
        new() { Success = false, Error = error, StatusCode = 404 };

    public static ServiceResult<T> Unauthorized(string error) =>
        new() { Success = false, Error = error, StatusCode = 401 };

    public static ServiceResult<T> Forbidden(string error) =>
        new() { Success = false, Error = error, StatusCode = 403 };
    public static ServiceResult<T> Created(T data) =>
    new() { Success = true, Data = data, StatusCode = 201 };

    public static ServiceResult<T> Conflict(string error) =>
        new() { Success = false, Error = error, StatusCode = 409 };

}
