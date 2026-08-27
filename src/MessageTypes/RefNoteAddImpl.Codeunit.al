namespace Origo.CloudEvents.Reference;

using Origo.APP.CloudEvents;

/// <summary>
/// Reference implementation of a WRITE message type. Demonstrates the mandatory isolation
/// pattern: the actual write happens in a separate codeunit (TableNo = "CE Message Argument
/// ori") invoked via Codeunit.Run(), so a failure is caught here and reported through
/// RespondWithLastError() without rolling back the outer transaction.
/// </summary>
codeunit 90003 "Ref Note Add Impl" implements "Cloud Event Msg Interface ori"
{
    Access = Internal;

    internal procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Ref Note");
    end;

    internal procedure GetDescription(): Text[250]
    begin
        exit('Creates a note record. Fails with a structured error if the id already exists.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpText: TextBuilder;
    begin
        HelpText.AppendLine('# Reference.Note.Add');
        HelpText.AppendLine(GetDescription());
        HelpText.AppendLine('');
        HelpText.AppendLine('**Request:** `{ "no": "NOTE-1", "text": "hello" }`');
        HelpText.AppendLine('**Response (success):** `{ "no": "NOTE-1" }`');
        HelpText.AppendLine('**Response (failure, e.g. duplicate no.):** structured error via `RespondWithLastError`, caught from the isolated write codeunit rather than pre-checked here.');
        Argument.SetResponseMarkdown(HelpText.ToText());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();

        // Write operations must run in an isolated sub-codeunit so a failure can be caught
        // here without rolling back the outer transaction (see AGENTS.md rule).
        if not Codeunit.Run(Codeunit::"Ref Note Add Process", Argument) then
            Argument.RespondWithLastError();
    end;
}
