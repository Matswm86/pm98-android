// FUN_00581e60  entry=00581e60  size=76 bytes

uint __fastcall FUN_00581e60(int param_1)

{
  byte bVar1;
  int iVar2;
  
  bVar1 = *(byte *)(param_1 + 0xa7);
  iVar2 = FUN_00582db0();
  return ((uint)*(byte *)(param_1 + 0x9f) +
         (uint)*(byte *)(param_1 + 0x9e) + (uint)bVar1 +
         iVar2 + (uint)*(byte *)(param_1 + 0x9c) + (uint)*(byte *)(param_1 + 0x9d)) / 6;
}


