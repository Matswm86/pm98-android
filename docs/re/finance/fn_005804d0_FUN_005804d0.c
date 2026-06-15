// FUN_005804d0  entry=005804d0  size=49 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

float10 __thiscall FUN_005804d0(int param_1,int param_2)

{
  float *pfVar1;
  int iVar2;
  float10 fVar3;
  
  fVar3 = (float10)_DAT_00638dd8;
  pfVar1 = (float *)(*(int *)(param_1 + 0x1e4) + 0x8c + param_2 * 0x20c);
  iVar2 = 0xe;
  do {
    fVar3 = fVar3 + (float10)*pfVar1;
    pfVar1 = pfVar1 + 1;
    iVar2 = iVar2 + -1;
  } while (iVar2 != 0);
  return fVar3;
}


