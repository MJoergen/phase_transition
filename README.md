# What is this about?

This project aims to demonstrate the phase transition between the liquid and vapor phases of a substance using a very
simple "liquid vapor model".  Specifically we want to exhibit the behavior around the critical point.

For reference, the critical point for water is at 374 degrees Celsius and 218 atmospheres of pressure.

This project is inspired by these two videoes:
* [first video](https://www.youtube.com/watch?v=itRV2jEtV8Q).
* [second video](https://www.youtube.com/watch?v=yEcysu5xZH0).

# What can you do?

* There is a small application in Ruby that you can run.
* (TODO) There is a larger implementation for FPGA that displays on a VGA output.

# Theory

Here I will try to briefly explain the theory of the implementation. It is all about Statistical Thermodynamics.

This project is a 2D model of a substance on a lattice. Each lattice site may either be or not be occupied by a
molecule of the substance.

## States

The state of the system consists of a lattice of sites.  For each lattice site $i$ we associate a variable $`s_i`$ which is
1 if the site is occupied by a molecule, and 0 otherwise (i.e. empty site in lattice).

For each state of the system, we can calculate the total occupation number $N$ and the total energy $E$:

```math
N = \sum_i s_i
```

```math
E = -\sum_{i,j \,\, neighbors} s_i \cdot s_j
```

In other words, the number $N$ simply counts the number of molecules currently in the system, while the energy $E$ is more
negative whenever two molecules are neighbors. This models a nearest neighbor attraction.

## Algorithm

We use a [Grand canonical ensemble](https://en.wikipedia.org/wiki/Grand_canonical_ensemble).

When the system is in thermal equilibrium the total Hamiltonian $H$ is minimized:

```math
H = E - C N
```

where $C$ is the chemical potential.

The algorithm chosen here is a Monte Carlo method, i.e. randomly jumping around the possible states while minimizing the
Hamiltonian.

At each step a site is chosen at random. Then the Hamiltonian is evaluated in two situation corresponding to the current
state of the site and the inverted state of the site. If the new value of the Hamiltonian is lower, then the state at
the site is inverted.

## Statistical Thermodynamics

We model a [Lattice gas](https://en.wikipedia.org/wiki/Ising_model#Lattice_gas), which is a special case of a Ising
model.

We attempt to determine the equilibrium probability distribution of this ensemble, using a
Monte Carlo method. This is also called [Statistical
thermodynamics](https://en.wikipedia.org/wiki/Statistical_mechanics#Statistical_thermodynamics).

The system is in contact (i.e. thermal and chemical equilibrium) with a large reservoir (environment), and combined they
exhibit conservation of energy and particle count. However, the system itself will be exchanging both energy and
particles with the reservoir, but the temperature and chemical potential will be in equilibrium.

The system we're modeling is the [Square lattice Ising model](https://en.wikipedia.org/wiki/Square_lattice_Ising_model).

We're using the [Metropolis-Hastings algorithm](https://en.wikipedia.org/wiki/Metropolis%E2%80%93Hastings_algorithm).


The equilibrium probability is given by:

```math
Probability = \exp\left((\Omega - H)/T\right)
```

where $T$ is the temperature (we set $k$ = 1). Here $\Omega$ is the grand potential and serves as a normalization factor;
it depends on the chemical potential $C$ and the temperature $T$, and we can therefore write:

```math
\Omega = \Omega(C, T)
```

$\Omega$ can be calculated from the normalization property as:

```math
\Omega(C, T) = -T \cdot \log \sum \exp\left(-H/T\right)
```

where the sum is over all possible states of the system.

Properties of the grand potential $\Omega$:

```math
N = -d\Omega/dC
```
```math
S = -d\Omega/dT
```

In others words

```math
d\Omega = -S dT - N dC
```

The average energy is

```math
<E> = \Omega + <N> C + ST
```

i.e.

```math
dE = T dS + C dN
```

Furthermore, the grand partition function $Z$ is related to the grand potential $\Omega$ via:

```math
Z = \exp\left(-\Omega/T\right)
```

See more details about variance and correlation in the wikipedia page on [Grand canonical
ensemble](https://en.wikipedia.org/wiki/Grand_canonical_ensemble#Grand_potential,_ensemble_averages,_and_exact_differentials).

In this model the critical point is around $C=-2$ and $T=0.57$.

The discontinuity is in $C$.


TBD: How to calculate entropy S from the probability distribution?

```math
S = \left<-\log Probability\right>
```

