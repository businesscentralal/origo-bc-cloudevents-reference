namespace Origo.CloudEvents.Reference.Legacy;

/// <summary>
/// Ordinary business logic, written with no awareness of Cloud Events. Two procedures,
/// two different shapes on purpose:
///  - ReserveStock: a plain function. No UI, no Commit(). Trivially wrappable.
///  - CancelReservation: interactive (Confirm) and transactionally unsafe (an early
///    Commit() before a second write that can still fail). NOT wrappable as-is -
///    see ADAPTING.md for why, and what has to change here before it can be.
/// </summary>
codeunit 90050 "Legacy Stock Mgt"
{
    /// <summary>
    /// Reserves quantity against an item. No dialogs, no intermediate commit - the whole
    /// operation is one transaction. This is the "easy" case for a Cloud Events wrapper.
    /// </summary>
    procedure ReserveStock(ItemNo: Code[20]; Quantity: Decimal): Boolean
    var
        Reservation: Record "Legacy Stock Reservation";
    begin
        if Quantity <= 0 then
            exit(false);

        if Reservation.Get(ItemNo) then begin
            Reservation.Quantity += Quantity;
            Reservation.Modify(true);
        end else begin
            Reservation.Init();
            Reservation."Item No." := ItemNo;
            Reservation.Quantity := Quantity;
            Reservation.Insert(true);
        end;
        exit(true);
    end;

    /// <summary>
    /// Cancels a reservation. Ordinary-looking BC code that is exactly what makes it
    /// unsafe to call headlessly: it asks the user a question, and it commits the
    /// deletion before the log write that follows - a failure in the log write does not
    /// roll back the cancellation. Fine for an interactive user who can see both steps
    /// happen; wrong for an automated caller. Do not wrap this procedure directly.
    /// </summary>
    procedure CancelReservation(ItemNo: Code[20])
    var
        Reservation: Record "Legacy Stock Reservation";
        Log: Record "Legacy Cancellation Log";
        ConfirmQst: Label 'Cancel the reservation for %1?', Comment = '%1 = item no.';
    begin
        if not Confirm(ConfirmQst, false, ItemNo) then
            exit;

        if not Reservation.Get(ItemNo) then
            exit;
        Reservation.Delete(true);
        Commit(); // Legacy behaviour: the deletion is final before the log write below runs.

        Log.Init();
        Log."Item No." := ItemNo;
        Log."Cancelled At" := CurrentDateTime();
        Log.Insert(true);
    end;
}
