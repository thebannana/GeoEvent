namespace EventService.API.Security;

public static class FileSignatureValidator
{
    public static async Task<bool> IsSupportedImageAsync(Stream stream, CancellationToken cancellationToken = default)
    {
        if (!stream.CanRead)
            return false;

        if (stream.CanSeek)
            stream.Position = 0;

        var buffer = new byte[12];
        var bytesRead = await stream.ReadAsync(buffer.AsMemory(0, buffer.Length), cancellationToken);

        if (stream.CanSeek)
            stream.Position = 0;

        if (bytesRead >= 3 &&
            buffer[0] == 0xFF &&
            buffer[1] == 0xD8 &&
            buffer[2] == 0xFF)
        {
            return true;
        }

        if (bytesRead >= 8 &&
            buffer[0] == 0x89 &&
            buffer[1] == 0x50 &&
            buffer[2] == 0x4E &&
            buffer[3] == 0x47 &&
            buffer[4] == 0x0D &&
            buffer[5] == 0x0A &&
            buffer[6] == 0x1A &&
            buffer[7] == 0x0A)
        {
            return true;
        }

        if (bytesRead >= 12 &&
            buffer[0] == 0x52 &&
            buffer[1] == 0x49 &&
            buffer[2] == 0x46 &&
            buffer[3] == 0x46 &&
            buffer[8] == 0x57 &&
            buffer[9] == 0x45 &&
            buffer[10] == 0x42 &&
            buffer[11] == 0x50)
        {
            return true;
        }

        return false;
    }
}