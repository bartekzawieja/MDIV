section .text
global mdiv

; argumenty funkcji mdiv(int64_t *x, size_t n, int64_t y):
;   rdi - wskaźnik na tablicę dzielnej (przechowującą liczby 64-bitowe)
;   rsi - rozmar tablicy dzielnej
;   rdx - dzielnik (liczba 64-bitowa)
;
; funkcja wykorzystuje dodatkowo rejestry:
;   rax - dzielenie z instrukcją div
;   rcx - indeks w pętli odwracającej
;   r9 - indeks w pętli dzielącej i odwracajćej
;   r10 - wielkość dzielnika
;   r11 - flagi informacyjne:
;     pierwszy bit od prawej - dzielna (1 = dzielna jest ujemna)
;     drugi bit od prawej - dzielnik (1 = dzielnik jest ujemny)
;     trzeci bit od prawej - dzielenie (1 = dzielenie już się odbyło)
mdiv:
    xor     r9, r9
    mov     r10, rdx                    ; zapisanie dzielnika
    xor     r11, r11

; sprawdzenie, czy dzielnik jest ujemny
    test    r10, r10                    ; dzielnik < 0 ?
    jns     dividend                    ; jeżeli nie, przejście dalej
    or      r11, 2                      ; włączenie flagi dzielnika
    neg     r10                         ; odwrócenie znaku dzielnika

dividend:
; sprawdzenie, czy dzielna jest ujemna
    cmp     QWORD [rdi + rsi*8 - 8], 0  ; dzielna >= 0 ?
    jge     division                    ; jeżeli tak, przejście dalej
    or      r11, 1                      ; włączenie flagi dzielnej
    jmp     inversion                   ; odwrócenie znaku dzielnej

division:
; przygotowanie dzielenia
    mov     r9, rsi                     ; indeks = wielkość tablicy
    xor     rdx, rdx                    ; reszta z dzielenia = 0

division_loop:
; iteracja dzielenia
    dec     r9
    mov     rax, QWORD [rdi + r9*8]     ; przygotowanie części dzielnej
    div     r10
    mov     QWORD [rdi + r9*8], rax     ; część dzielnej = część ilorazu

    test    r9, r9                      ; indeks != 0 ?
    jne     division_loop               ; jeżeli tak, kolejna iteracja

; zakończnie dzielenia
    mov     rax, rdx                    ; wynik = reszta z dzielenia
    or      r11, 4                      ; włącznie flagi dzielenia

; sprawdzenie czy reszta ma być ujemna
    test    r11, 1                      ; flaga dzielnej ?
    jz      quotient                    ; jeżeli tak, przejście dalej
    neg     rax                         ; odwrócenie znaku dzielnej

quotient:
; sprawdzenie czy iloraz ma być ujemny
    cmp     r11, 5                      ; flagi dzielnej && dzielenia ?
    je      inversion                   ; jeżeli tak, odwrócenie ilorazu
    cmp     r11, 6                      ; flagi dzielnika && dzielenia ?
    je      inversion                   ; jeżeli tak, odwrócenie ilorazu

; sprawdzenie nadmiaru (overflow)
    cmp     QWORD [rdi + rsi*8 - 8], 0  ; dzielna >= 0 ?
    jge     correct                     ; jeżeli tak, przejście dalej
    div     r9                          ; podzielenie przez 0, błąd

correct:
    ret

inversion:
; przygotowanie odwrócenia znaku
    stc                                 ; carry = 1
    mov     rcx, rsi                    ; indeks = wielkość tablicy
inversion_loop:
; iteracja odwrócenia znaku
    not     QWORD [rdi + r9*8]          ; odwrócenie bitów części dzielnej
    adc     QWORD [rdi + r9*8], 0       ; część dzielnej += carry
    inc     r9
    loop    inversion_loop

    test    r11, 4                      ; flaga dzielenia ?
    jz      division                    ; jeżeli nie, dzielenie
    ret