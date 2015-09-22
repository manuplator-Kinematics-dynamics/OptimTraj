%%%% Derive Equations - Five Link Biped Model %%%%
%
% This script derives the equations of motion, as well as some other useful
% equations (kinematics, contact forces, ...) for the five-link biped
% model. 
%
%
% Nomenclature:
%
% - There are five links, which will be numbered starting with "1" for the
% stance leg tibia, increasing as the links are father from the base joint,
% and ending with "5" for the swing leg tibia.
%   1 - stance leg tibia (lower leg)
%   2 - stance leg femur  (upper leg)
%   3 - torso
%   4 - swing leg femur
%   5 - swing leg tibia
%
% - This script uses absolute angles, which are represented with "q". All
% angles use positive convention, with the zero angle corresponding to a
% vertically aligned link configuration. [q] = [0] has the torso balanced
% upright, with both legs fully extended straight below it.
%
% - Derivatives with respect to time are notated by prepending a "d". For
% example the rate of change in an absolute angle is "dq" and angular
% acceleration would be "ddq"
%
% - Joint positions are given with "P", center of mass positions are "G"
%

clc; clear;

%%%% Link state and derivatives
syms q1 q2 q3 q4 q5 'real' % Absolute link orientations
syms dq1 dq2 dq3 dq4 dq5 'real' % Absolute link angular rates
syms ddq1 ddq2 ddq3 ddq4 ddq5 'real' % Absolute link angular accelerations

%%%% System inputs (controls)
syms u1 'real' % Torque acting on stance leg tibia from ground
syms u2 'real' % torque acting on stance leg femur from stance leg tibia
syms u3 'real' % torque acting on torso from the stance leg femur
syms u4 'real' % torque acting on swing leg femur from torso
syms u5 'real' % torque acting on swing leg tibia from swing leg femur

%%%% Physical paramters 
syms m1 m2 m3 m4 m5 'real' % Link masses
syms c1 c2 c3 c4 c5 'real' % center of mass distance from joint
syms l1 l2 l3 l4 l5 'real' % link length
syms I1 I2 I3 I4 I5 'real' % link moment of inertia about center of mass
syms g 'real'  %Acceleration due to gravity

%%%% Contact Forces:
syms Fx Fy 'real'   %Contact forces at stance foot

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                Set up coordinate system and unit vectors                %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

i = sym([1;0]);   %Horizontal axis
j = sym([0;1]);   %Vertical axis

e1 = cos(q1)*(j) + sin(q1)*(-i);  %unit vector from P0 -> P1, (contact point to stance knee)
e2 = cos(q2)*(j) + sin(q2)*(-i);  %unit vector from P1 -> P2, (stance knee to hip)
e3 = cos(q3)*(j) + sin(q3)*(-i);  %unit vector from P2 -> P3, (hip to shoulders);
e4 = -cos(q4)*(j) - sin(q4)*(-i);  %unit vector from P2 -> P4, (hip to swing knee);
e5 = -cos(q5)*(j) - sin(q5)*(-i);  %unit vector from P4 -> P5, (swing knee to swing foot);

P0 = 0*i + 0*j;   %stance foot = Contact point = origin
P1 = P0 + l1*e1;  %stance knee
P2 = P1 + l2*e2;  %hip
P3 = P2 + l3*e3;  %shoulders
P4 = P2 + l4*e4;  %swing knee
P5 = P4 + l5*e5;  %swing foot

G1 = P1 - c1*e1;  % CoM stance leg tibia
G2 = P2 - c2*e2;  % CoM stance leg febur
G3 = P3 - c3*e3;  % CoM torso
G4 = P2 + c4*e4;  % CoM swing leg femur 
G5 = P4 + c5*e5;  % CoM swing leg tibia
G = (m1*G1 + m2*G2 + m3*G3 + m4*G4 + m5*G5)/(m1+m2+m3+m4+m5);  %Center of mass for entire robot



%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                             Derivatives                                 %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

q = [q1;q2;q3;q4;q5];   
dq = [dq1;dq2;dq3;dq4;dq5];
ddq = [ddq1;ddq2;ddq3;ddq4;ddq5];

% Neat trick to compute derivatives using the chain rule
derivative = @(in)( jacobian(in,[q;dq])*[dq;ddq] );

% Compute derivatives for the CoM of each link:
dG1 = derivative(G1);  ddG1 = derivative(dG1);
dG2 = derivative(G2);  ddG2 = derivative(dG2);
dG3 = derivative(G3);  ddG3 = derivative(dG3);
dG4 = derivative(G4);  ddG4 = derivative(dG4);
dG5 = derivative(G5);  ddG5 = derivative(dG5);
dG = derivative(G);  ddG = derivative(dG);


%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                      Single-Stance Dynamics                             %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

% I solve the dynamics here by carefully selecting angular momentum balance
% equations about each joint, working my way out the kinematic tree from
% the root.

%%%% Define a function for doing '2d' cross product: dot(a x b, k)
cross2d = @(a,b)(a(1)*b(2) - a(2)*b(1));

%%%% Weight of each link:
w1 = -m1*g*j;
w2 = -m2*g*j;
w3 = -m3*g*j;
w4 = -m4*g*j;
w5 = -m5*g*j;

%%%% AMB - entire system @ P0
eqnTorque0 = ...
    cross2d(G1-P0,w1) + ...
    cross2d(G2-P0,w2) + ...
    cross2d(G3-P0,w3) + ...
    cross2d(G4-P0,w4) + ...
    cross2d(G5-P0,w5) + ...
    u1;

eqnInertia0 = ...
    cross2d(G1-P0,m1*ddG1) + ddq1*I1 + ...
    cross2d(G2-P0,m2*ddG2) + ddq2*I2 + ...
    cross2d(G3-P0,m3*ddG3) + ddq3*I3 + ...
    cross2d(G4-P0,m4*ddG4) + ddq4*I4 + ...
    cross2d(G5-P0,m5*ddG5) + ddq5*I5;

%%%% AMB - swing leg, torso, stance femer  @ stance knee
eqnTorque1 = ...
    cross2d(G2-P1,w2) + ...
    cross2d(G3-P1,w3) + ...
    cross2d(G4-P1,w4) + ...
    cross2d(G5-P1,w5) + ...
    u2;

eqnInertia1 = ...
    cross2d(G2-P1,m2*ddG2) + ddq2*I2  + ...
    cross2d(G3-P1,m3*ddG3) + ddq3*I3  + ...
    cross2d(G4-P1,m4*ddG4) + ddq4*I4  + ...
    cross2d(G5-P1,m5*ddG5) + ddq5*I5 ;

%%%% AMB - swing leg, torso @ hip
eqnTorque2 = ...
    cross2d(G3-P2,w3) + ...
    cross2d(G4-P2,w4) + ...
    cross2d(G5-P2,w5) + ...
    u3;

eqnInertia2 = ...
    cross2d(G3-P2,m3*ddG3) + ddq3*I3  + ...
    cross2d(G4-P2,m4*ddG4) + ddq4*I4  + ...
    cross2d(G5-P2,m5*ddG5) + ddq5*I5 ;

%%%% AMB - swing leg @ hip
eqnTorque3 = ...
    cross2d(G4-P2,w4) + ...
    cross2d(G5-P2,w5) + ...
    u4;

eqnInertia3 = ...
    cross2d(G4-P2,m4*ddG4) + ddq4*I4  + ...
    cross2d(G5-P2,m5*ddG5) + ddq5*I5 ;

%%%% AMB - swing tibia % swing knee
eqnTorque4 = ...
    cross2d(G5-P4,w5) + ...
    u5;

eqnInertia4 = ...
    cross2d(G5-P4,m5*ddG5) + ddq5*I5 ;

%%%% Collect and solve equations:
eqns = [...
    eqnTorque0 - eqnInertia0;
    eqnTorque1 - eqnInertia1;
    eqnTorque2 - eqnInertia2;
    eqnTorque3 - eqnInertia3;
    eqnTorque4 - eqnInertia4];

[MassMatrix, GenForce] = equationsToMatrix(eqns,ddq);



%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                    Contact Forces  +  Energy                            %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

%%%% Contact Forces:
eqnForce5 = w1 + w2 + w3 + w4 + w5 + Fx*i + Fy*j;
eqnInertia5 = (m1+m2+m3+m4+m5)*ddG;
[AA,bb] = equationsToMatrix(eqnForce5-eqnInertia5,[Fx;Fy]);
ContactForces = AA\bb;

%%%% Energy:
KineticEnergy = ...
    0.5*m1*dot(dG1,dG1) + 0.5*I1*dq1^2 + ...
    0.5*m2*dot(dG2,dG2) + 0.5*I2*dq2^2 + ...
    0.5*m3*dot(dG3,dG3) + 0.5*I3*dq3^2 + ...
    0.5*m4*dot(dG4,dG4) + 0.5*I4*dq4^2 + ...
    0.5*m5*dot(dG5,dG5) + 0.5*I5*dq5^2;
PotentialEnergy = ...
    m1*g*G1(2) + ...
    m2*g*G2(2) + ...
    m3*g*G3(2) + ...
    m4*g*G4(2) + ...
    m5*g*G5(2);



%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                        Heel-Strike Dynamics                             %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

% Computes the collision map for heel strike.
syms dG1mx dG2mx dG3mx dG4mx dG5mx 'real' % Center of mass velocities before heel-strike (minus)
syms dG1my dG2my dG3my dG4my dG5my 'real' % Center of mass velocities before heel-strike (minus)
syms dq1m dq2m dq3m dq4m dq5m 'real' % angular rate of links before heel-strike

dG1m = [dG1mx; dG1my];
dG2m = [dG2mx; dG2my];
dG3m = [dG3mx; dG3my];
dG4m = [dG4mx; dG4my];
dG5m = [dG5mx; dG5my];

%%%% AMB - entire system @ P0
eqnHs0m = ...   %Before collision
    cross2d(G1-P0,m1*dG1m) + dq1m*I1 + ...
    cross2d(G2-P0,m2*dG2m) + dq2m*I2 + ...
    cross2d(G3-P0,m3*dG3m) + dq3m*I3 + ...
    cross2d(G4-P0,m4*dG4m) + dq4m*I4 + ...
    cross2d(G5-P0,m5*dG5m) + dq5m*I5;
eqnHs0 = ...   %After collision
    cross2d(G1-P0,m1*dG1) + dq1*I1 + ...
    cross2d(G2-P0,m2*dG2) + dq2*I2 + ...
    cross2d(G3-P0,m3*dG3) + dq3*I3 + ...
    cross2d(G4-P0,m4*dG4) + dq4*I4 + ...
    cross2d(G5-P0,m5*dG5) + dq5*I5;


%%%% AMB - swing leg, torso, stance femer  @ stance knee
eqnHs1m = ...   %Before collision
    cross2d(G2-P1,m2*dG2m) + dq2m*I2 + ...
    cross2d(G3-P1,m3*dG3m) + dq3m*I3 + ...
    cross2d(G4-P1,m4*dG4m) + dq4m*I4 + ...
    cross2d(G5-P1,m5*dG5m) + dq5m*I5;
eqnHs1 = ...   %After collision
    cross2d(G2-P1,m2*dG2) + dq2*I2 + ...
    cross2d(G3-P1,m3*dG3) + dq3*I3 + ...
    cross2d(G4-P1,m4*dG4) + dq4*I4 + ...
    cross2d(G5-P1,m5*dG5) + dq5*I5;


%%%% AMB - swing leg, torso  @ hip
eqnHs2m = ...   %Before collision
    cross2d(G3-P2,m3*dG3m) + dq3m*I3 + ...
    cross2d(G4-P2,m4*dG4m) + dq4m*I4 + ...
    cross2d(G5-P2,m5*dG5m) + dq5m*I5;
eqnHs2 = ...   %After collision
    cross2d(G3-P2,m3*dG3) + dq3*I3 + ...
    cross2d(G4-P2,m4*dG4) + dq4*I4 + ...
    cross2d(G5-P2,m5*dG5) + dq5*I5;


%%%% AMB - swing leg @ hip
eqnHs3m = ...   %Before collision
    cross2d(G4-P2,m4*dG4m) + dq4m*I4 + ...
    cross2d(G5-P2,m5*dG5m) + dq5m*I5;
eqnHs3 = ...   %After collision
    cross2d(G4-P2,m4*dG4) + dq4*I4 + ...
    cross2d(G5-P2,m5*dG5) + dq5*I5;

%%%% AMB - swing tibia @ swing knee
eqnHs4m = ...   %Before collision
    cross2d(G5-P4,m5*dG5m) + dq5m*I5;
eqnHs4 = ...   %After collision
    cross2d(G5-P4,m5*dG5) + dq5*I5;


%%%% Collect and solve equations:
eqnHs = [...
    eqnHs0m - eqnHs0;
    eqnHs1m - eqnHs1;
    eqnHs2m - eqnHs2;
    eqnHs3m - eqnHs3;
    eqnHs4m - eqnHs4];
[MM,ff] = equationsToMatrix(eqnHs,dq);











%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                       Write Dynamics file                               %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

% Resort to some Matlab trickery here to get vectorized dynamics for
% trajectory optimization:
Idx = find(MassMatrix);  
MassMatrixVec = MassMatrix(Idx);  % Column vector of non-zero elements

matlabFunction(MassMatrixVec, Idx, GenForce,...
    'file','autoGen_dynSs.m',...
    'vars',{...
    'q1','q2','q3','q4','q5',...
    'dq1','dq2','dq3','dq4','dq5',...
    'u1','u2','u3','u4','u5',...
    'm1','m2','m3','m4','m5',...
    'I1','I2','I3','I4','I5',...
    'l1','l2','l3','l4',...
    'c1','c2','c3','c4','c5',...
    'g'},...
    'outputs',{'MM','Idx','F'});

matlabFunction(MM,ff,...
    'file','autoGen_dynHs.m',...
    'vars',{...
    'q1','q2','q3','q4','q5',...
    'dq1m','dq2m','dq3m','dq4m','dq5m',...
    'dG1mx', 'dG2mx', 'dG3mx', 'dG4mx', 'dG5mx',...
    'dG1my', 'dG2my', 'dG3my', 'dG4my', 'dG5my',...
    'm1','m2','m3','m4','m5',...
    'I1','I2','I3','I4','I5',...
    'l1','l2','l3','l4',...
    'c1','c2','c3','c4','c5'},...
    'outputs',{'MM','ff'});


%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                       Write Contact Forces + Energy                     %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

matlabFunction(ContactForces(1),ContactForces(2),...
    'file','autoGen_contactForce.m',...
    'vars',{...
    'q1','q2','q3','q4','q5',...
    'dq1','dq2','dq3','dq4','dq5',...
    'ddq1','ddq2','ddq3','ddq4','ddq5',...
    'm1','m2','m3','m4','m5',...
    'l1','l2','l3','l4',...
    'c1','c2','c3','c4','c5',...
    'g'},...
    'outputs',{'Fx','Fy'});


matlabFunction(KineticEnergy, PotentialEnergy,...
    'file','autoGen_energy.m',...
    'vars',{...
    'q1','q2','q3','q4','q5',...
    'dq1','dq2','dq3','dq4','dq5',...
    'm1','m2','m3','m4','m5',...
    'I1','I2','I3','I4','I5',...
    'l1','l2','l3','l4',...
    'c1','c2','c3','c4','c5',...
    'g'},...
    'outputs',{'KE','PE'});



%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                        Write Kinematics Files                           %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

P = [P1; P2; P3; P4; P5];
G = [G1; G2; G3; G4; G5];
matlabFunction(P,G,'file','autoGen_getPoints.m',...
    'vars',{...
    'q1','q2','q3','q4','q5',...
    'l1','l2','l3','l4','l5',...
    'c1','c2','c3','c4','c5'},...
    'outputs',{'P','G'});


dG = [dG1; dG2; dG3; dG4; dG5];
matlabFunction(dG,'file','autoGen_comVel.m',...
    'vars',{...
    'q1','q2','q3','q4','q5',...
    'dq1','dq2','dq3','dq4','dq5',...
    'l1','l2','l3','l4',...
    'c1','c2','c3','c4','c5'},...
    'outputs',{'dG'});














