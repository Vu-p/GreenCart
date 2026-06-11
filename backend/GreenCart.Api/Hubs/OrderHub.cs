using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace GreenCart.Api.Hubs;

[Authorize]
public sealed class OrderHub : Hub
{
    public Task JoinOrder(string orderId) =>
        Groups.AddToGroupAsync(Context.ConnectionId, OrderGroup(orderId));

    public Task LeaveOrder(string orderId) =>
        Groups.RemoveFromGroupAsync(Context.ConnectionId, OrderGroup(orderId));

    public static string OrderGroup(string orderId) => $"order:{orderId}";
}
