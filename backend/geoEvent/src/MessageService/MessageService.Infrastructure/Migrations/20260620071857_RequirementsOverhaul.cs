using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MessageService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RequirementsOverhaul : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Messages");

            migrationBuilder.AlterColumn<string>(
                name: "Type",
                table: "ChatThreads",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "LikesCount",
                table: "ChatMessages",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.CreateIndex(
                name: "IX_ChatThreadParticipants_ThreadId_UserId",
                table: "ChatThreadParticipants",
                columns: new[] { "ThreadId", "UserId" });

            migrationBuilder.CreateIndex(
                name: "IX_ChatThreadParticipants_UserId_LeftAt",
                table: "ChatThreadParticipants",
                columns: new[] { "UserId", "LeftAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_SenderId",
                table: "ChatMessages",
                column: "SenderId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_ThreadId",
                table: "ChatMessages",
                column: "ThreadId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessageLikes_UserId_LikedAt",
                table: "ChatMessageLikes",
                columns: new[] { "UserId", "LikedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ChatThreadParticipants_ThreadId_UserId",
                table: "ChatThreadParticipants");

            migrationBuilder.DropIndex(
                name: "IX_ChatThreadParticipants_UserId_LeftAt",
                table: "ChatThreadParticipants");

            migrationBuilder.DropIndex(
                name: "IX_ChatMessages_SenderId",
                table: "ChatMessages");

            migrationBuilder.DropIndex(
                name: "IX_ChatMessages_ThreadId",
                table: "ChatMessages");

            migrationBuilder.DropIndex(
                name: "IX_ChatMessageLikes_UserId_LikedAt",
                table: "ChatMessageLikes");

            migrationBuilder.AlterColumn<int>(
                name: "Type",
                table: "ChatThreads",
                type: "int",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<int>(
                name: "LikesCount",
                table: "ChatMessages",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldDefaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Messages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Content = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: false),
                    EditedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    EventId = table.Column<int>(type: "int", nullable: true),
                    IsDeletedByRecipient = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    IsDeletedBySender = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    IsRead = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    LikesCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    ReadAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RecipientId = table.Column<int>(type: "int", nullable: false),
                    SenderId = table.Column<int>(type: "int", nullable: false),
                    SentAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Messages", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Messages_EventId",
                table: "Messages",
                column: "EventId");

            migrationBuilder.CreateIndex(
                name: "IX_Messages_IsRead",
                table: "Messages",
                column: "IsRead");

            migrationBuilder.CreateIndex(
                name: "IX_Messages_RecipientId",
                table: "Messages",
                column: "RecipientId");

            migrationBuilder.CreateIndex(
                name: "IX_Messages_SenderId",
                table: "Messages",
                column: "SenderId");

            migrationBuilder.CreateIndex(
                name: "IX_Messages_SenderId_RecipientId",
                table: "Messages",
                columns: new[] { "SenderId", "RecipientId" });

            migrationBuilder.CreateIndex(
                name: "IX_Messages_SenderId_RecipientId_SentAt",
                table: "Messages",
                columns: new[] { "SenderId", "RecipientId", "SentAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Messages_SentAt",
                table: "Messages",
                column: "SentAt");
        }
    }
}
