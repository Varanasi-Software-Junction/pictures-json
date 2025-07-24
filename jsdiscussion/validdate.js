// Write your JavaScript code here
function dateCheck(day,month,year)
{
if(year<1)
{
console.log("Invalid Year");
return;
}
if(month<1 || month>12)
{
console.log("Invalid Month");
return;
}
if(day<1)
{
console.log("Invalid Day");
return;
}
let maxdays=31;
if(month==4 || month==6 || month==9 || month==11)
maxdays=30;
if(month==2)
{
if((year % 400==0) ||(year%4==0 && year%100!=0))
maxdays=29;
else
maxdays=28;
}
if(day>maxdays)
{
console.log("Invalid Day");
return;
}
console.log("Valid Date");
return;
}
dateCheck(29,88,2025);
