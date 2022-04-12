# Creating the CH4 first guess

Below is FORTRAN-like pseudocode to derive the first guess for methane in NUCAPS.

```
data ff = -0.35, 7.1, 150.
coeff = 7.308, 0.0339, 0.0483, -0.1394, -0.1279,0.0624, 0.0214, -0.0119, -0.0134, -0.0102,  0.00224

do L = 1, 100

  XX(1) = sin(alat *pi/180.)

  XX(2) = SQRT(Pobs(L))
  XX(3) = alog(1.+Pobs(L))
  XX(4)= XX(1)**2
  XX(5)= XX(3)**2
  XX(6)= XX(1)**2*XX(3)
  XX(7)= XX(1)*XX(3)
  XX(8)= XX(1)**3
  XX(9)= XX(3)**3
  XX(10)= XX(1)*XX(3)**2

  XX(11)= alog(20.+Pobs(L))* cos(alat*pi/180.)**8
  XX(12)= 1. + XX(1)**8

  sum = 7.321
  do i = 2, 11
    sum = sum + coeff(i)*XX(i-1)
  enddo

  ch4mr(L)= exp(sum) - exp(ff(1)*XX(11) + ff(2)/(1.+Pobs(L)/(ff(3)*XX(12)) ))*exp((-alog(100./(50. + Pobs(L)))**8))

enddo
```
