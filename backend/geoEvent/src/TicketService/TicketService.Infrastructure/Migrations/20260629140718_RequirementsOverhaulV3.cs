using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TicketService.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class RequirementsOverhaulV3 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "PendingPaymentCreatedAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PendingPaymentMethod",
                table: "Reservations",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PendingProviderOrderId",
                table: "Reservations",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RefundDecisionReason",
                table: "Reservations",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RefundReason",
                table: "Reservations",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RefundRequestStatus",
                table: "Reservations",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "RefundRequestedAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "RefundReviewedAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "RefundReviewedByUserId",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_PendingProviderOrderId",
                table: "Reservations",
                column: "PendingProviderOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_RefundRequestStatus",
                table: "Reservations",
                column: "RefundRequestStatus");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reservations_PendingProviderOrderId",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_RefundRequestStatus",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "PendingPaymentCreatedAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "PendingPaymentMethod",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "PendingProviderOrderId",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "RefundDecisionReason",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "RefundReason",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "RefundRequestStatus",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "RefundRequestedAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "RefundReviewedAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "RefundReviewedByUserId",
                table: "Reservations");
        }
    }
}
