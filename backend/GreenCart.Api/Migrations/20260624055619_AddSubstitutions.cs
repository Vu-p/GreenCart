using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GreenCart.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddSubstitutions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Substitutions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    OrderId = table.Column<Guid>(type: "TEXT", nullable: false),
                    OrderItemId = table.Column<Guid>(type: "TEXT", nullable: false),
                    OriginalProductId = table.Column<Guid>(type: "TEXT", nullable: false),
                    ReplacementProductId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Status = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    Note = table.Column<string>(type: "TEXT", maxLength: 1000, nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Substitutions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Substitutions_OrderItems_OrderItemId",
                        column: x => x.OrderItemId,
                        principalTable: "OrderItems",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Substitutions_Orders_OrderId",
                        column: x => x.OrderId,
                        principalTable: "Orders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Substitutions_Products_OriginalProductId",
                        column: x => x.OriginalProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Substitutions_Products_ReplacementProductId",
                        column: x => x.ReplacementProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Substitutions_OrderId",
                table: "Substitutions",
                column: "OrderId");

            migrationBuilder.CreateIndex(
                name: "IX_Substitutions_OrderItemId",
                table: "Substitutions",
                column: "OrderItemId");

            migrationBuilder.CreateIndex(
                name: "IX_Substitutions_OriginalProductId",
                table: "Substitutions",
                column: "OriginalProductId");

            migrationBuilder.CreateIndex(
                name: "IX_Substitutions_ReplacementProductId",
                table: "Substitutions",
                column: "ReplacementProductId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Substitutions");
        }
    }
}
