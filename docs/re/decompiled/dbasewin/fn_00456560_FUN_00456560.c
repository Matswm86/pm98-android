// FUN_00456560  entry=00456560  size=42 bytes

void __thiscall FUN_00456560(void *this,LPCSTR param_1)

{
  int iVar1;
  
  lstrcpyA((LPSTR)((int)this + 0x3b4),param_1);
  iVar1 = FUN_004630b0((LPSTR)((int)this + 0x3b4));
  *(int *)((int)this + 0x3d4) = iVar1;
  return;
}


