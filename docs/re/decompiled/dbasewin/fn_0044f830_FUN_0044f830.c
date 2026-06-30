// FUN_0044f830  entry=0044f830  size=98 bytes

char __thiscall
FUN_0044f830(void *this,int param_1,uint param_2,int param_3,int param_4,undefined1 param_5,
            byte param_6)

{
  undefined1 uVar1;
  char cVar2;
  undefined4 extraout_ECX;
  undefined4 unaff_ESI;
  int iVar3;
  uint uVar4;
  int iVar5;
  
  uVar1 = param_5;
  iVar3 = CONCAT22((short)((uint)unaff_ESI >> 0x10),(ushort)param_6);
  cVar2 = '\x01';
  do {
    if ((short)iVar3 < 1) {
      return cVar2;
    }
    param_1 = param_1 + 1;
    param_2 = param_2 + 1;
    param_3 = param_3 + 1;
    param_4 = param_4 + 1;
    uVar4 = param_2;
    iVar5 = iVar3;
    FUN_004042d0(&stack0xffffffec,0);
    cVar2 = FUN_0043d1f0(this,&param_1,uVar4,iVar5);
    iVar3 = iVar3 - (CONCAT31((int3)((uint)extraout_ECX >> 8),uVar1) & 0xffff00ff);
  } while (cVar2 != '\0');
  return '\0';
}


