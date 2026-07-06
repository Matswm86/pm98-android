// FUN_004f81e0  entry=004f81e0  size=202 bytes

undefined4 FUN_004f81e0(void)

{
  void *local_10;
  undefined1 *puStack_c;
  undefined4 local_8;
  
  puStack_c = &LAB_006162a0;
  local_10 = ExceptionList;
  local_8 = 0;
  ExceptionList = &local_10;
  FUN_004f8440();
  while( true ) {
    while( true ) {
      DAT_0066b200 = 0;
      DAT_0066b1d4 = FUN_004f9380();
      if (DAT_0066b1d4 != 0x4e35) break;
      DAT_0066b1e4 = 0;
      DAT_0066b1e8 = 0;
      FUN_004f8a00();
    }
    if (DAT_0066b1d4 != 0x4e36) break;
    DAT_0066b1e4 = 1;
    DAT_0066b1e8 = 0;
    FUN_004f8a00();
  }
  local_8 = 0xffffffff;
  if (DAT_0066b1d4 == 0x4e3a) {
    DAT_0066b1d4 = 1;
  }
  else {
    DAT_0066b1d4 = DAT_0066b1d4 + -0x4e1e;
  }
  FUN_004f8750();
  ExceptionList = local_10;
  return 1;
}


