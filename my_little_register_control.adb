with MaRTE.Integer_Types; use MaRTE.Integer_Types;
with MaRTE.Hal.IO; use MaRTE.Hal.IO;
with Ada.Unchecked_Conversion;

package body My_Little_Register_Control is
  PP_BASE_REG : constant := 16#378#;
  SP_BASE_REG : constant := 16#3F8#;

  -- Parallel Data Register
  ------------------------------------------------------------------------------
  PP_DATA_REG : constant := PP_BASE_REG + 0;

  type Hopper_Function_T is (Load, Unload);
  for Hopper_Function_T use (Load=>1,Unload=>2);

  type Parallel_Data_Register_T is record
    First_Sorter_Closed : Boolean;
    Second_Sorter_Closed : Boolean;
    Hopper : Hopper_Function_T;
  end record;

  for Parallel_Data_Register_T use
    record
      First_Sorter_Closed at 0 range 3..3;
      Second_Sorter_Closed at 0 range 2..2;
      Hopper at 0 range 0..1;
    end record;

  for Parallel_Data_Register_T'Size use 8;

  function Write_PDR is new Ada.Unchecked_Conversion(Parallel_Data_Register_T, Unsigned_8);
  function Read_PDR is new Ada.Unchecked_Conversion(Unsigned_8, Parallel_Data_Register_T);

  -- Parallel Status Register
  ------------------------------------------------------------------------------
  PP_STATUS_REG : constant := PP_BASE_REG + 1;

  type Parallel_Status_Register_T is record
      NotReady : Boolean;
    end record;

  for Parallel_Status_Register_T'Size use 8;

  function Read_PSR is new Ada.Unchecked_Conversion(Unsigned_8, Parallel_Status_Register_T);

  -- Parallel Control Register
  ------------------------------------------------------------------------------
  PP_CONTROL_REG : constant := PP_BASE_REG + 2;

  type Parallel_Control_Register_T is record
    Enable_IRQ : Boolean;
  end record;

  for Parallel_Control_Register_T use
    record
      Enable_IRQ at 0 range 4..4;
    end record;

  for Parallel_Control_Register_T'Size use 8;

  function Write_PCR is new Ada.Unchecked_Conversion(Parallel_Control_Register_T, Unsigned_8);
  function Read_PCR is new Ada.Unchecked_Conversion(Unsigned_8, Parallel_Control_Register_T);

  -- Interrupt Mask Register
  ------------------------------------------------------------------------------
  PC_INTERRUPT_MASK_REG : constant := 16#21#;

  type Interrupt_Mask_Register_T is record
    Parallel : Boolean;
    Floppy_Disk_Controller : Boolean;
    Sound_Card : Boolean;
    Serial_Port_1 : Boolean;
    Serial_Port_2 : Boolean;
    PIC2 : Boolean;
    Keyboard : Boolean;
    System_Timer : Boolean;
  end record;

  for Interrupt_Mask_Register_T use
    record
      Parallel at 0 range 7..7;
      Floppy_Disk_Controller at 0 range 6..6;
      Sound_Card at 0 range 5..5;
      Serial_Port_1 at 0 range 4..4;
      Serial_Port_2 at 0 range 3..3;
      PIC2 at 0 range 2..2;
      Keyboard at 0 range 1..1;
      System_Timer at 0 range 0..0;
    end record;

  for Interrupt_Mask_Register_T'Size use 8;

  function Write_IMR is new Ada.Unchecked_Conversion(Interrupt_Mask_Register_T, Unsigned_8);
  function Read_IMR is new Ada.Unchecked_Conversion(Unsigned_8, Interrupt_Mask_Register_T);

  -- Serial Divisor Register
  ------------------------------------------------------------------------------
  SP_DLLR_REG : constant := SP_BASE_REG + 0; -- low byte
  SP_DLHR_REG : constant := SP_BASE_REG + 1; -- high byte

  -- Serial Interrupt Enable Register
  ------------------------------------------------------------------------------
  SP_IER_REG : constant := SP_BASE_REG + 1;

  type Serial_Interrupt_Enable_Register_T is record
    Low_Power_Mode : Boolean;
    Sleep_Mode : Boolean;
    Modem_Status_Interrupt : Boolean;
    Receiver_Line_Status_Interrupt : Boolean;
    Transmitter_Holding_Register_Empty_Interrupt : Boolean;
    Received_Data_Available_Interrupt : Boolean;
  end record;

  for Serial_Interrupt_Enable_Register_T use
    record
      Low_Power_Mode at 0 range 5..5;
      Sleep_Mode at 0 range 4..4;
      Modem_Status_Interrupt at 0 range 3..3;
      Receiver_Line_Status_Interrupt at 0 range 2..2;
      Transmitter_Holding_Register_Empty_Interrupt at 0 range 1..1;
      Received_Data_Available_Interrupt at 0 range 0..0;
    end record;

  for Serial_Interrupt_Enable_Register_T'Size use 8;

  function Write_IER is new Ada.Unchecked_Conversion(Serial_Interrupt_Enable_Register_T, Unsigned_8);
  function Read_IER is new Ada.Unchecked_Conversion(Unsigned_8, Serial_Interrupt_Enable_Register_T);

  -- Serial Line Control Register
  ------------------------------------------------------------------------------
  SP_LCR_REG : constant := SP_BASE_REG + 3;

  type Parity_Select_T is (No_Parity, Odd_Parity, Even_Parity, High_Parity, Low_Parity);
  for Parity_Select_T use (No_Parity=>0,Odd_Parity=>1,Even_Parity=>3,High_Parity=>5,Low_Parity=>7);

  type Stop_Bit_Length_T is (One_Bit, Two_Bits);
  for Stop_Bit_Length_T use (One_Bit=>0,Two_Bits=>1);

  type Word_Length_T is (Eight_Bit_Words);
  for Word_Length_T use (Eight_Bit_Words=>3);

  type Serial_Line_Control_Register_T is record
    Divisor_Latch_Access : Boolean;
    Parity : Parity_Select_T;
    Stop_Bits : Stop_Bit_Length_T;
    Word_Length : Word_Length_T;
  end record;

  for Serial_Line_Control_Register_T use
    record
      Divisor_Latch_Access at 0 range 7..7;
      Parity at 0 range 3..5;
      Stop_Bits at 0 range 2..2;
      Word_Length at 0 range 0..1;
    end record;

  for Serial_Line_Control_Register_T'Size use 8;

  function Write_LCR is new Ada.Unchecked_Conversion(Serial_Line_Control_Register_T, Unsigned_8);
  function Read_LCR is new Ada.Unchecked_Conversion(Unsigned_8, Serial_Line_Control_Register_T);

  ------------------------------------------------------------------------------

  -- The metal detector interrupts the target via the parallel port interrupt
  -- and the proximity detector via the serial port CTS (clear to send) modem
  -- control input.
  procedure Initialize_Interfaces is
    Timr : Interrupt_Mask_Register_T;
    Tpcr : Parallel_Control_Register_T;
    Sier : Serial_Interrupt_Enable_Register_T;
    Slcr : Serial_Line_Control_Register_T;
  begin
    -- Enable parallel control IRQ
    Tpcr := Read_PCR(Inb_P(PP_CONTROL_REG));
    Tpcr.Enable_IRQ := true;
    Outb_P(PP_CONTROL_REG, Write_PCR(Tpcr));

    -- Configure serial line control
    Slcr := Read_LCR(Inb_P(SP_LCR_REG));
    Slcr.Word_Length := Eight_Bit_Words;
    Slcr.Stop_Bits := One_Bit;
    Slcr.Parity := No_Parity;
    Slcr.Divisor_Latch_Access := true;
    Outb_P(SP_LCR_REG, Write_LCR(Slcr));

    -- Set serial divisor to 12 (9600bps)
    Outb_P(SP_DLHR_REG, 16#0#);
    Outb_P(SP_DLLR_REG, 16#0C#);

    -- Enable serial port model status interrupt
    Slcr := Read_LCR(Inb_P(SP_LCR_REG));
    Slcr.Divisor_Latch_Access := false;
    Outb_P(SP_LCR_REG, Write_LCR(Slcr));

    Sier := Read_IER(Inb_P(SP_IER_REG));
    Sier.Modem_Status_Interrupt := true;
    Outb_P(SP_IER_REG, Write_IER(Sier));

    -- Enable parallel and serial port interrupts
    -- Note bits are cleared to enable an interrupt
    Timr := Read_IMR(Inb_P(PC_INTERRUPT_MASK_REG));
    Timr.Parallel := false;
    Timr.Serial_Port_1 := false;
    Outb_P(PC_INTERRUPT_MASK_REG, Write_IMR(Timr));
  end Initialize_Interfaces;

  procedure Write_Hopper_Command_Bits(Command : Hopper_Command) is
    Tpdr : Parallel_Data_Register_T;
  begin
    Tpdr := Read_PDR(Inb_P(PP_DATA_REG));

    if Command = Unload then
      Tpdr.Hopper := Unload;
    elsif Command = Load then
      Tpdr.Hopper := Load;
    end if;

    Outb_P(PP_DATA_REG, Write_PDR(Tpdr));
  end Write_Hopper_Command_Bits;

  procedure Write_Sorter_Command_Bits(First : Sorter_Command; Second : Sorter_Command) is
    Tpdr : Parallel_Data_Register_T;
  begin
    Tpdr := Read_PDR(Inb_P(PP_DATA_REG));
    Tpdr.First_Sorter_Closed := (First = Closed);
    Tpdr.Second_Sorter_Closed := (Second = Closed);
    Outb_P(PP_DATA_REG, Write_PDR(Tpdr));
  end Write_Sorter_Command_Bits;

  procedure Wait_For_Software_Control is
    Tpsr : Parallel_Status_Register_T;
  begin
    loop
      Tpsr := Read_PSR(Inb_P(PP_STATUS_REG));
      exit when not Tpsr.NotReady;
    end loop;
  end Wait_For_Software_Control;
end My_Little_Register_Control;
