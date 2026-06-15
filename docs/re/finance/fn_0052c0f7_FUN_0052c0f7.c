// FUN_0052c0f7  entry=0052c0f7  size=446 bytes

void FUN_0052c0f7(void)

{
  int iVar1;
  int unaff_ESI;
  code *unaff_EDI;
  undefined1 *puVar2;
  
  (*unaff_EDI)();
  puVar2 = &DAT_00666f70;
  iVar1 = lstrlenA(&stack0x00000034);
  (*unaff_EDI)(&stack0x00000034 + iVar1,puVar2);
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&stack0x0000002c,0xe6,0x35,0x19e,0x42,0x100);
  }
  else {
    FUN_005da180(&stack0x0000002c,0xe6,0x35,0x19e,0x42,0x100,1);
  }
  FUN_005d9d30(0);
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_House_and_car_0065be1c,0xe6,0x57,0x1a4,100,0x100);
  }
  else {
    FUN_005da180(s_House_and_car_0065be1c,0xe6,0x57,0x1a4,100,0x100,1);
  }
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) & 0xffffffdf;
  FUN_005d9d50(s_ProMan10_006551e0);
  *(undefined1 *)(unaff_ESI + 0x14c) = 1;
  FUN_005d9d30(0xd6aace);
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) != 0) {
    FUN_005da180(s_OFFER_0065bc80,1,1,0x17,0x67,0x100,1);
    return;
  }
  FUN_005d9d80(s_OFFER_0065bc80,1,1,0x17,0x67,0x100);
  return;
}


