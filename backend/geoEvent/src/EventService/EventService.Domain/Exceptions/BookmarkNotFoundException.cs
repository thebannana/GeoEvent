namespace EventService.Domain.Exceptions;

public class BookmarkNotFoundException : Exception
{
    public BookmarkNotFoundException(int bookmarkId)
        : base($"Bookmark with ID {bookmarkId} was not found.") { }
}