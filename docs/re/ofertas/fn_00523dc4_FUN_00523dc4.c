// FUN_00523dc4  entry=00523dc4  size=258 bytes

undefined4 FUN_00523dc4(void)

{
  int iVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  int unaff_EBX;
  int unaff_EBP;
  int unaff_ESI;
  undefined4 in_stack_00000010;
  
  uVar2 = FUN_00436fb0(0x129,0x1b);
  uVar3 = FUN_00436fb0(0x96,0x10);
  FUN_00436fd0(uVar3,uVar2);
  (**(code **)(unaff_EBP + 0xc0))();
  FUN_005beae0(s_ProMan14_00656830);
  *(undefined1 *)(unaff_ESI + 0x4e9) = 0x20;
  iVar1 = *(int *)(unaff_ESI + 0x1928);
  FUN_00437020(0x8c,0x8c,0xb4);
  CRect::CRect((CRect *)&stack0x00000014,0x1ee,0x1ba,0x25e,0x1d3);
  (**(code **)(iVar1 + 0xc0))();
  FUN_004f4860(unaff_ESI,*(undefined4 *)(unaff_EBX + 0x10),0);
  FUN_004f4b00(unaff_ESI,0x1bf,0);
  FUN_00465d90(unaff_ESI,*(undefined4 *)(unaff_EBX + 0x10));
  FUN_00523ed0();
  FUN_00523f70();
  return in_stack_00000010;
}


