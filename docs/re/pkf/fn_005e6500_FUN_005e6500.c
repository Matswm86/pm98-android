// FUN_005e6500  entry=005e6500  size=35 bytes

void FUN_005e6500(int param_1)

{
  int iVar1;
  
  iVar1 = 0;
  do {
    *(byte *)(iVar1 + param_1) =
         *(byte *)(iVar1 + param_1) ^ ((char)iVar1 + -0x21) * ((char)iVar1 + '\x01');
    iVar1 = iVar1 + 1;
  } while (iVar1 < 0x14);
  return;
}


