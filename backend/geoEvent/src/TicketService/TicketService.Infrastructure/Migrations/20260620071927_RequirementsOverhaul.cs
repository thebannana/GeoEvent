using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TicketService.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class RequirementsOverhaul : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<DateTime>(
                name: "PaidAt",
                table: "PaymentDetails",
                type: "datetime2",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "Currency",
                table: "PaymentDetails",
                type: "nvarchar(3)",
                maxLength: 3,
                nullable: false,
                defaultValue: "BAM",
                oldClrType: typeof(string),
                oldType: "nvarchar(3)",
                oldMaxLength: 3,
                oldDefaultValue: "EUR");

            migrationBuilder.AddColumn<string>(
                name: "ProviderOrderId",
                table: "PaymentDetails",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProviderPaymentId",
                table: "PaymentDetails",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RefundTransactionId",
                table: "PaymentDetails",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ProviderOrderId",
                table: "PaymentDetails");

            migrationBuilder.DropColumn(
                name: "ProviderPaymentId",
                table: "PaymentDetails");

            migrationBuilder.DropColumn(
                name: "RefundTransactionId",
                table: "PaymentDetails");

            migrationBuilder.AlterColumn<DateTime>(
                name: "PaidAt",
                table: "PaymentDetails",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified),
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Currency",
                table: "PaymentDetails",
                type: "nvarchar(3)",
                maxLength: 3,
                nullable: false,
                defaultValue: "EUR",
                oldClrType: typeof(string),
                oldType: "nvarchar(3)",
                oldMaxLength: 3,
                oldDefaultValue: "BAM");
        }
    }
}
