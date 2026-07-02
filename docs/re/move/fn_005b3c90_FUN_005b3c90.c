// FUN_005b3c90  entry=005b3c90  size=82 bytes

int FUN_005b3c90(int param_1,int param_2)

{
  int iVar1;
  
  if (0x7fff < param_2) {
    iVar1 = FUN_005ec250();
    iVar1 = ((int)(param_2 + (param_2 >> 0x1f & 0xffU)) >> 8) * iVar1;
    return ((int)(iVar1 + (iVar1 >> 0x1f & 0x7fU)) >> 7) + param_1;
  }
  iVar1 = FUN_005ec250();
  return ((int)(iVar1 * param_2 + (iVar1 * param_2 >> 0x1f & 0x7fffU)) >> 0xf) + param_1;
}


