namespace Origo.CloudEvents.Reference.LegacyAdapter;

using Origo.APP.CloudEvents;
using Origo.CloudEvents.Reference.Legacy;

/// <summary>
/// The "easy" case: ReserveStock has no dialogs and no intermediate commit, so this
/// impl codeunit calls it directly. No change to Legacy App was needed for this one.
/// </summary>
codeunit 90100 "Legacy Stock Reserve Impl" implements "Cloud Event Msg Interface ori"
{
    Access = Internal;

    internal procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Legacy Stock Reservation");
    end;

    internal procedure GetDescription(): Text[250]
    begin
        exit('Reserves quantity against an item in Legacy App. Thin wrapper - Legacy App''s ReserveStock was already safe to call headlessly.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpText: TextBuilder;
    begin
        HelpText.AppendLine('# Legacy.Stock.Reserve');
        HelpText.AppendLine(GetDescription());
        HelpText.AppendLine('');
        HelpText.AppendLine('**Request:** `{ "itemNo": "1000", "quantity": 5 }`');
        HelpText.AppendLine('**Response (success):** `{ "itemNo": "1000", "quantity": 5 }`');
        HelpText.AppendLine('**Response (failure):** structured error via `RespondWithError` for invalid quantity.');
        Argument.SetResponseMarkdown(HelpText.ToText());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        LegacyStockMgt: Codeunit "Legacy Stock Mgt";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        ItemNoToken: JsonToken;
        QuantityToken: JsonToken;
        ItemNo: Code[20];
        Quantity: Decimal;
        InvalidQuantityErr: Label 'Quantity must be greater than zero.';
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();

        RequestJson := Argument.GetRequestJson();
        if not RequestJson.Get('itemNo', ItemNoToken) then begin
            Argument.RespondWithError('Missing required field ''itemNo''.');
            exit;
        end;
        if not RequestJson.Get('quantity', QuantityToken) then begin
            Argument.RespondWithError('Missing required field ''quantity''.');
            exit;
        end;

        ItemNo := CopyStr(ItemNoToken.AsValue().AsText(), 1, 20);
        Quantity := QuantityToken.AsValue().AsDecimal();

        if not LegacyStockMgt.ReserveStock(ItemNo, Quantity) then begin
            Argument.RespondWithError(InvalidQuantityErr);
            exit;
        end;

        ResponseJson.Add('itemNo', ItemNo);
        ResponseJson.Add('quantity', Quantity);
        Argument.SetResponseJson(ResponseJson);
    end;
}
