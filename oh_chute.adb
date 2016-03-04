with Text_IO;
with Ada.Calendar; use Ada.Calendar;
with Register_Control; use Register_Control;
with Ada.Interrupts.Names; use Ada.Interrupts.Names;
with System; use System;
with Ada.Interrupts; use Ada.Interrupts;

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

  protected type Sensor_Interrupt is
    pragma Interrupt_Priority(Interrupt_Priority'First);
    entry Wait_For_Ball(B: out Ball_Sensed; T: out Time);

    entry Sensed(B: Ball_Sensed);

    -- metal detector
    procedure Metal_Interrupt;
    pragma Interrupt_Handler(Metal_Interrupt);

    procedure Proximity_Interrupt;
    pragma Interrupt_Handler(Proximity_Interrupt);
  private
    Interrupted : Boolean := false;
    Last_Ball : Ball_Sensed;
    Time_Triggered : Time;
  end Sensor_Interrupt;

  protected body Sensor_Interrupt is
    entry Wait_For_Ball(B: out Ball_Sensed; T: out Time) when Interrupted is
    begin
      B := Last_Ball;
      T := Time_Triggered;
      Interrupted := false;
    end Wait_For_Ball;

    entry Sensed(B: Ball_Sensed) when not Interrupted is
    begin
      Last_Ball := B;
      Time_Triggered := Clock;
      Interrupted := true;
    end Sensed;

    procedure Metal_Interrupt is
    begin
      -- TODO: fix warning here, bounded buffer?
      Sensed(Metal);
    end Metal_Interrupt;

    procedure Proximity_Interrupt is
    begin
      -- TODO: fix warning here, bounded buffer?
      Sensed(Unknown);
    end Proximity_Interrupt;
  end Sensor_Interrupt;

  S : Sensor_Interrupt;

  -- returns ball type and time detected,
  -- blocks the Ada.Interruptscalling task until a ball is detected
  procedure Get_Next_Sensed_Ball(B: out Ball_Sensed; T: out Time) is
  begin
    S.Wait_For_Ball(B, T);
  end Get_Next_Sensed_Ball;
begin
  Attach_Handler(S.Metal_Interrupt'Unrestricted_Access, Parallel_Line);
  Attach_Handler(S.Proximity_Interrupt'Unrestricted_Access, Serial_Line);

  Initialize_Interfaces;

  Text_IO.Put_Line("Turn chutes now");
  Wait_For_Software_Control;
end Oh_Chute;
