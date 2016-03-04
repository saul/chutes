with Text_IO;
with Ada.Calendar; use Ada.Calendar;
with Chute;
with Register_Control; use Register_Control;

package body Oh_Chute is
    -- load hopper
    procedure Hopper_Load is
    begin
      Write_Hopper_Command_Bits(Load);
    end Hopper_Load;

    -- unload hopper
    procedure Hopper_Unload is
    begin
      Write_Hopper_Command_Bits(Unload);
    end Hopper_Unload;

    -- first solenoid open & second closed
    procedure Sorter_Metal is
    begin
      Write_Sorter_Command_Bits(Open, Closed);
    end Sorter_Metal;

    -- second solenoid open & first closed
    procedure Sorter_Glass is
    begin
      Write_Sorter_Command_Bits(Closed, Open);
    end Sorter_Glass;

    -- neither solenoid open
    procedure Sorter_Close is
    begin
      Write_Sorter_Command_Bits(Closed, Closed);
    end Sorter_Close;

    -- returns ball type and time detected,
    -- blocks the calling task until a ball is detected
    procedure Get_Next_Sensed_Ball(B: out Chute.Ball_Sensed; T: out Time) is
    begin
      Chute.Get_Next_Sensed_Ball(B, T);
    end Get_Next_Sensed_Ball;
end Oh_Chute;
