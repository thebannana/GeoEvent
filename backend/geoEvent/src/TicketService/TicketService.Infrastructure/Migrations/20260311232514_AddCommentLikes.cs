using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TicketService.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddCommentLikes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reservations_Status",
                table: "Reservations");

            migrationBuilder.AddColumn<DateTime>(
                name: "ExpiredAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_Status_ExpiresAt",
                table: "Reservations",
                columns: new[] { "Status", "ExpiresAt" });

            migrationBuilder.CreateIndex(
                name: "IX_IssuedTickets_IssuedAt",
                table: "IssuedTickets",
                column: "IssuedAt");

            migrationBuilder.CreateIndex(
                name: "IX_IssuedTickets_Status",
                table: "IssuedTickets",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reservations_Status_ExpiresAt",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_IssuedTickets_IssuedAt",
                table: "IssuedTickets");

            migrationBuilder.DropIndex(
                name: "IX_IssuedTickets_Status",
                table: "IssuedTickets");

            migrationBuilder.DropColumn(
                name: "ExpiredAt",
                table: "Reservations");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_Status",
                table: "Reservations",
                column: "Status");
        }
    }
}
