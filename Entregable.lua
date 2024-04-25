function Init()
    strategy:name("Prueba Trading Station");
    strategy:description("Prueba de programacion para OQ Trading");

    strategy.parameters:addString("Cuenta", "Cuenta", "Elija la cuenta a operar", "");
    strategy.parameters:setFlag("Cuenta", core.FLAG_ACCOUNT);
    strategy.parameters:addInteger("Total", "Total", "Especifica el tamaño total de la orden en el símbolo especificado. En (k) para divisas, en lotes para otros símbolos", 1000);
    strategy.parameters:addInteger("Suborders", "Suborders", " Especifica el numero total de ordenes de mercado en el que se debe dividir el “Total”", 10);
    strategy.parameters:addInteger("Stop", "Stop", "Especifica el numero de pips/puntos para el stop que se aplica a cada suborder. Si =0, no aplicar orden de stop.", 20);
    strategy.parameters:addInteger("Limit", "Limite", "Especifica el numero de pips/puntos para el limite que se aplica a cada suborder. Si =0, no aplicar orden limite.", 20);
end

local cuenta;
local simbolo;
local total;
local suborders;
local stop;
local limit;
local offer;

function Prepare(onlyName)
    local name = profile:id() .. "(" .. instance.bid:instrument() .. ", " .. tostring(cuenta) .. ", " .. tostring(total) .. ", " .. tostring(suborders) .. ", " .. tostring(stop) .. ", " .. tostring(limit) .. ")";
    if onlyName then
        return;
    end

    cuenta = instance.parameters.Cuenta;
    simbolo = instance.bid:instrument();
    total = instance.parameters.Total;
    suborders = instance.parameters.Suborders;
    stop = instance.parameters.Stop;
    limit = instance.parameters.Limit;
    offer = core.host:findTable("offers"):find("Instrument", instance.bid:instrument()).OfferID;
    gSource = ExtSubscribe(1, nil, "t1", instance.parameters.Type == "Bid", "bar");
end

local create = true;

function ExtUpdate()
    if create then
        create = false;
        local monto = math.floor(total / suborders);
        local monto_residual = total % suborders;
        for i = 1, suborders do
            if suborders == i then
                monto = monto + monto_residual;
            end
            local valuemap = core.valuemap();
            valuemap.Command = "CreateOrder";
            valuemap.OrderType = "OM";
            valuemap.OfferID = offer;
            valuemap.AcctID = cuenta;
            if simbolo == "XAU/USD" or simbolo == "BTC/USD" or string.find(simbolo, "/") == nil then
                valuemap.Quantity = monto;
            else
                valuemap.Quantity = monto * 1000;
            end
            valuemap.BuySell = "B";
            valuemap.GTC = "GTC";
            if stop > 0 then
                valuemap.PegTypeStop = "M";
                valuemap.PegPriceOffsetPipsStop = -stop;
            end
            if limit > 0 then
                valuemap.PegTypeLimit = "M";
                valuemap.PegPriceOffsetPipsLimit = limit;
            end
            local success, msg = terminal:execute(100, valuemap);
            if not (success) then
                terminal:alertMessage(instance.bid:instrument(), instance.bid[NOW], "create order failed:" .. msg, instance.bid:date(NOW));
            else
                requestId = core.parseCsv(msg, ",")[0];
                terminal:alertMessage(instance.bid:instrument(), instance.bid[NOW], "order sent:" .. requestId, instance.bid:date(NOW));
            end
        end
    end
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");