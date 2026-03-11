using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EventService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCommentLikesTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Events_Genres_GenreId",
                table: "Events");

            migrationBuilder.DropForeignKey(
                name: "FK_Events_Segments_SegmentId",
                table: "Events");

            migrationBuilder.DropForeignKey(
                name: "FK_Events_SubGenres_SubGenreId",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_Segments_Name",
                table: "Segments");

            migrationBuilder.DropIndex(
                name: "IX_EventLikes_EventId_UserId",
                table: "EventLikes");

            migrationBuilder.AlterColumn<string>(
                name: "WebsiteUrl",
                table: "Venues",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(500)",
                oldMaxLength: 500,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "VenueType",
                table: "Venues",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "TimeZone",
                table: "Venues",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "PhoneNumber",
                table: "Venues",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(20)",
                oldMaxLength: 20,
                oldNullable: true);

            migrationBuilder.AlterColumn<bool>(
                name: "IsVerified",
                table: "Venues",
                type: "bit",
                nullable: false,
                defaultValue: false,
                oldClrType: typeof(bool),
                oldType: "bit");

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "Venues",
                type: "nvarchar(2000)",
                maxLength: 2000,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Events",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(20)",
                oldMaxLength: 20);

            migrationBuilder.AlterColumn<string>(
                name: "ExternalUrl",
                table: "Events",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(500)",
                oldMaxLength: 500,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "ExternalId",
                table: "Events",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Memo",
                table: "Bookmarks",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(500)",
                oldMaxLength: 500);

            migrationBuilder.CreateTable(
                name: "CommentLikes",
                columns: table => new
                {
                    LikeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CommentId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    LikedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CommentLikes", x => x.LikeId);
                    table.ForeignKey(
                        name: "FK_CommentLikes_Comments_CommentId",
                        column: x => x.CommentId,
                        principalTable: "Comments",
                        principalColumn: "CommentId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Venues_CityId",
                table: "Venues",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_Venues_CityId_VenueType",
                table: "Venues",
                columns: new[] { "CityId", "VenueType" });

            migrationBuilder.CreateIndex(
                name: "IX_Venues_IsVerified",
                table: "Venues",
                column: "IsVerified");

            migrationBuilder.CreateIndex(
                name: "IX_Venues_Longitude_Latitude",
                table: "Venues",
                columns: new[] { "Longitude", "Latitude" });

            migrationBuilder.CreateIndex(
                name: "IX_Venues_Name",
                table: "Venues",
                column: "Name");

            migrationBuilder.CreateIndex(
                name: "IX_Venues_VenueType",
                table: "Venues",
                column: "VenueType");

            migrationBuilder.CreateIndex(
                name: "IX_SubGenres_GenreId_IsActive",
                table: "SubGenres",
                columns: new[] { "GenreId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_Segments_Name",
                table: "Segments",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Events_CityId_StartDateTime",
                table: "Events",
                columns: new[] { "CityId", "StartDateTime" });

            migrationBuilder.CreateIndex(
                name: "IX_Events_CityId_Status",
                table: "Events",
                columns: new[] { "CityId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_Events_GenreId_StartDateTime",
                table: "Events",
                columns: new[] { "GenreId", "StartDateTime" });

            migrationBuilder.CreateIndex(
                name: "IX_Events_Longitude_Latitude",
                table: "Events",
                columns: new[] { "Longitude", "Latitude" });

            migrationBuilder.CreateIndex(
                name: "IX_Events_SegmentId_StartDateTime",
                table: "Events",
                columns: new[] { "SegmentId", "StartDateTime" });

            migrationBuilder.CreateIndex(
                name: "IX_Events_Status_StartDateTime",
                table: "Events",
                columns: new[] { "Status", "StartDateTime" });

            migrationBuilder.CreateIndex(
                name: "IX_EventLikes_EventId",
                table: "EventLikes",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_EventLikes_LikedAt",
                table: "EventLikes",
                column: "LikedAt");

            migrationBuilder.CreateIndex(
                name: "IX_EventLikes_UserId_EventId",
                table: "EventLikes",
                columns: new[] { "UserId", "EventId" },
                unique: true,
                filter: "[UserId] IS NOT NULL AND [EventId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_CommentLikes_CommentId",
                table: "CommentLikes",
                column: "CommentId");

            migrationBuilder.CreateIndex(
                name: "IX_CommentLikes_UserId",
                table: "CommentLikes",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_CommentLikes_UserId_CommentId",
                table: "CommentLikes",
                columns: new[] { "UserId", "CommentId" },
                unique: true,
                filter: "UserId IS NOT NULL AND CommentId IS NOT NULL");

            migrationBuilder.AddForeignKey(
                name: "FK_Events_Genres_GenreId",
                table: "Events",
                column: "GenreId",
                principalTable: "Genres",
                principalColumn: "GenreId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Events_Segments_SegmentId",
                table: "Events",
                column: "SegmentId",
                principalTable: "Segments",
                principalColumn: "SegmentId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Events_SubGenres_SubGenreId",
                table: "Events",
                column: "SubGenreId",
                principalTable: "SubGenres",
                principalColumn: "SubGenreId",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Events_Genres_GenreId",
                table: "Events");

            migrationBuilder.DropForeignKey(
                name: "FK_Events_Segments_SegmentId",
                table: "Events");

            migrationBuilder.DropForeignKey(
                name: "FK_Events_SubGenres_SubGenreId",
                table: "Events");

            migrationBuilder.DropTable(
                name: "CommentLikes");

            migrationBuilder.DropIndex(
                name: "IX_Venues_CityId",
                table: "Venues");

            migrationBuilder.DropIndex(
                name: "IX_Venues_CityId_VenueType",
                table: "Venues");

            migrationBuilder.DropIndex(
                name: "IX_Venues_IsVerified",
                table: "Venues");

            migrationBuilder.DropIndex(
                name: "IX_Venues_Longitude_Latitude",
                table: "Venues");

            migrationBuilder.DropIndex(
                name: "IX_Venues_Name",
                table: "Venues");

            migrationBuilder.DropIndex(
                name: "IX_Venues_VenueType",
                table: "Venues");

            migrationBuilder.DropIndex(
                name: "IX_SubGenres_GenreId_IsActive",
                table: "SubGenres");

            migrationBuilder.DropIndex(
                name: "IX_Segments_Name",
                table: "Segments");

            migrationBuilder.DropIndex(
                name: "IX_Events_CityId_StartDateTime",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_Events_CityId_Status",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_Events_GenreId_StartDateTime",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_Events_Longitude_Latitude",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_Events_SegmentId_StartDateTime",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_Events_Status_StartDateTime",
                table: "Events");

            migrationBuilder.DropIndex(
                name: "IX_EventLikes_EventId",
                table: "EventLikes");

            migrationBuilder.DropIndex(
                name: "IX_EventLikes_LikedAt",
                table: "EventLikes");

            migrationBuilder.DropIndex(
                name: "IX_EventLikes_UserId_EventId",
                table: "EventLikes");

            migrationBuilder.AlterColumn<string>(
                name: "WebsiteUrl",
                table: "Venues",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(1000)",
                oldMaxLength: 1000,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "VenueType",
                table: "Venues",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "TimeZone",
                table: "Venues",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "PhoneNumber",
                table: "Venues",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30,
                oldNullable: true);

            migrationBuilder.AlterColumn<bool>(
                name: "IsVerified",
                table: "Venues",
                type: "bit",
                nullable: false,
                oldClrType: typeof(bool),
                oldType: "bit",
                oldDefaultValue: false);

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "Venues",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(2000)",
                oldMaxLength: 2000,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Events",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "ExternalUrl",
                table: "Events",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(1000)",
                oldMaxLength: 1000,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "ExternalId",
                table: "Events",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(255)",
                oldMaxLength: 255,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Memo",
                table: "Bookmarks",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(500)",
                oldMaxLength: 500,
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Segments_Name",
                table: "Segments",
                column: "Name");

            migrationBuilder.CreateIndex(
                name: "IX_EventLikes_EventId_UserId",
                table: "EventLikes",
                columns: new[] { "EventId", "UserId" },
                unique: true,
                filter: "[EventId] IS NOT NULL AND [UserId] IS NOT NULL");

            migrationBuilder.AddForeignKey(
                name: "FK_Events_Genres_GenreId",
                table: "Events",
                column: "GenreId",
                principalTable: "Genres",
                principalColumn: "GenreId");

            migrationBuilder.AddForeignKey(
                name: "FK_Events_Segments_SegmentId",
                table: "Events",
                column: "SegmentId",
                principalTable: "Segments",
                principalColumn: "SegmentId");

            migrationBuilder.AddForeignKey(
                name: "FK_Events_SubGenres_SubGenreId",
                table: "Events",
                column: "SubGenreId",
                principalTable: "SubGenres",
                principalColumn: "SubGenreId");
        }
    }
}
