using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GreenCart.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddPayOsPayments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PayOsCheckoutUrl",
                table: "Orders",
                type: "TEXT",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "PayOsOrderCode",
                table: "Orders",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PayOsPaymentLinkId",
                table: "Orders",
                type: "TEXT",
                maxLength: 120,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PaymentProvider",
                table: "Orders",
                type: "TEXT",
                maxLength: 32,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Orders_PayOsOrderCode",
                table: "Orders",
                column: "PayOsOrderCode",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Orders_PayOsOrderCode",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "PayOsCheckoutUrl",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "PayOsOrderCode",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "PayOsPaymentLinkId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "PaymentProvider",
                table: "Orders");
        }
    }
}
