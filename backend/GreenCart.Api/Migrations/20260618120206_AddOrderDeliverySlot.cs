using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GreenCart.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddOrderDeliverySlot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DeliverySlot",
                table: "Orders",
                type: "TEXT",
                maxLength: 120,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeliverySlot",
                table: "Orders");
        }
    }
}
