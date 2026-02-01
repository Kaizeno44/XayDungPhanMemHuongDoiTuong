using MassTransit;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using System.Reflection;

namespace Shared.Kernel.Extensions;

public static class MassTransitExtensions
{
    public static IBusRegistrationConfigurator AddEventBus(this IBusRegistrationConfigurator configurator, IConfiguration configuration, Assembly assembly)
    {
        // Tự động tìm các Consumer trong project gọi hàm này
        configurator.AddConsumers(assembly);

        configurator.UsingRabbitMq((context, cfg) =>
        {
            // Đọc cấu hình từ appsettings.json
            var rabbitMqHost = configuration["RabbitMq:Host"] ?? "rabbitmq"; 
            // "rabbitmq" là tên service trong docker-compose

            cfg.Host(rabbitMqHost, "/", h =>
            {
                h.Username("guest");
                h.Password("guest");
            });

            // Tắt yêu cầu License của MassTransit (nếu có)
            cfg.ConfigureEndpoints(context);
        });

        return configurator;
    }
}
