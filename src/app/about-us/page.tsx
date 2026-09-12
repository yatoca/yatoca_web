'use client';
import React from 'react';
import './AboutUs.css';
import Wrapper from '@/components/basic/wrapper';
import SafeArea from '@/components/basic/safe-area';
import { LogoAmbosSVG, LogoBicentarioSVG, LogoIdeaSVG } from '@/constants/svgs';
import about_us_principles from '@/assets/images/about_us_principles.jpg';
import about_us_principles_mobile from '@/assets/images/about_us_principles_mobile.png';
import Image from 'next/image';


const AboutUs: React.FC = () => {
  const sectionColor = '#0059A6';
  const sectionTextColor = '#FFFFFF';
  const companies = [
    { id: 1, element: <LogoAmbosSVG /> },
    { id: 2, element: <LogoBicentarioSVG /> },
    { id: 3, element: <LogoIdeaSVG /> },
  ]
  return (
    <>
      <Wrapper color={sectionColor} textColor={sectionTextColor} footerColor={sectionTextColor} logoColor={sectionTextColor}>
        <>
          <>
            <SafeArea>
              <div style={{ backgroundColor: sectionColor }}>
                <div className="about-us-photo" />
                <div className="location-divider" />
              </div>
            </SafeArea>
            <SafeArea>
              <div className='d-flex flex-row w100 gap'>
                <div className='about-us-p1 d-flex w100 flex-col'>
                  <div>Ya nos dijeron que nada cambia (como tu
                    ex) , que ya fue (como tu casi algo), que el
                    Perú está roto (no diré como quién).</div>
                  <div className="about-us-divider" />
                  <div>No nos compramos ese floro, queremos un país distinto.</div>
                  <div className="about-us-divider" />
                  <div>Los jóvenes somos el <span style={{ color: '#D9B3D6' }}>30% de votantes</span> (no es poca cosa) . Lo que nos importa debe ser tomado en serio.</div>
                  <div className="about-us-divider" />
                  <div>Ya toca hablar.</div>
                  <div>Ya toca actuar.</div>
                  <div>Ya toca que nos escuchen.</div>
                </div>
                <div className='about-us-p2' />
              </div>
            </SafeArea>
            <SafeArea>
              <div className="location-divider-2" />
            </SafeArea>
            <div className="about-us-principles">
              <SafeArea>
                <div className="about-us-principles-desktop d-flex flex-row gap w100">
                  <div className="about-us-principles-p1" />
                  <div className="about-us-principles-p2">
                    <Image src={about_us_principles} alt="about-us-principles-img-desktop" className="about-us-principles-img-desktop" />
                    <Image src={about_us_principles_mobile} alt="about-us-principles-img-mobile" className="about-us-principles-img-mobile" />
                  </div>
                  <div className="about-us-principles-p3" />
                  <div className="about-us-principles-p4 textWhite">
                    <div className="uppercase fs96 thunder-fw-bold-lc" style={{ lineHeight: 'normal' }}>Principios</div>
                    <div style={{ minHeight: 35 }} />
                    <div className="fs16">Aquí realmente escuchamos y no juzgamos. El objetivo es construir entre todos, algo mejor.</div>
                    <div style={{ minHeight: 35 }} />
                    <div className="thunder-fw-bold-lc fs64" style={{ color: '#D9B3D6' }}>01</div>
                    <div style={{ minHeight: 35 }} />
                    <div className="fs16"><span className="fw700">Independencia absoluta.</span> No nos casamos con nadie. Ni partidos, ni ideologías, ni intereses económicos. Transparentes, sin vueltas. La verdad como es.</div>
                    <div className="about-us-principles-divider" />
                    <div className="thunder-fw-bold-lc fs64" style={{ color: '#D9B3D6' }}>02</div>
                    <div style={{ minHeight: 35 }} />
                    <div className="fs16"><span className="fw700">Espacios seguros. </span> Queremos hablar con libertad, sin miedo. Lo que digas acá está protegido.</div>
                    <div className="about-us-principles-divider" />
                    <div className="thunder-fw-bold-lc fs64" style={{ color: '#D9B3D6' }}>03</div>
                    <div style={{ minHeight: 35 }} />
                    <div className="fs16"><span className="fw700">Diversidad real.</span> Distintas regiones, experiencias, formas de pensar y de ver el mundo. Aquí todas las voces son escuchadas. Avanzamos juntos, o no la hacemos.</div>
                  </div>
                </div>
              </SafeArea>
            </div>
            <div className="about-us-principles-mobile">
              <div className="about-us-principles-mobile d-flex flex-col w100">
                <SafeArea>
                  <>
                    <div className="uppercase fs96 thunder-fw-bold-lc textWhite" style={{ lineHeight: 'normal' }}>Principios</div>
                    <div style={{ minHeight: 71 }} />
                  </>
                </SafeArea>
                <div className="about-us-principles-p2">
                  <Image src={about_us_principles} alt="about-us-principles-img" />
                </div>
                <SafeArea>
                  <div className="about-us-principles-p4 textWhite">
                    <div style={{ minHeight: 55 }} />
                    <div className="fs16">Aquí realmente escuchamos y no juzgamos. El objetivo es construir entre todos, algo mejor.</div>
                    <div style={{ minHeight: 35 }} />
                    <div className="thunder-fw-bold-lc fs96" style={{ color: '#D9B3D6' }}>01</div>
                    <div style={{ minHeight: 35 }} />
                    <div className="fs16"><span className="fw700">Independencia absoluta.</span> No nos casamos con nadie. Ni partidos, ni ideologías, ni intereses económicos. Transparentes, sin vueltas. La verdad como es.</div>
                    <div className="about-us-principles-divider" />
                    <div className="thunder-fw-bold-lc fs96" style={{ color: '#D9B3D6' }}>02</div>
                    <div style={{ minHeight: 35 }} />
                    <div className="fs16"><span className="fw700">Espacios seguros. </span> Queremos hablar con libertad, sin miedo. Lo que digas acá está protegido.</div>
                    <div className="about-us-principles-divider" />
                    <div className="thunder-fw-bold-lc fs96" style={{ color: '#D9B3D6' }}>03</div>
                    <div style={{ minHeight: 35 }} />
                    <div className="fs16"><span className="fw700">Diversidad real.</span> Distintas regiones, experiencias, formas de pensar y de ver el mundo. Aquí todas las voces son escuchadas. Avanzamos juntos, o no la hacemos.</div>
                  </div>
                </SafeArea>
              </div>
            </div>
            <SafeArea>
              <>
                <div className="about-us-companies-desktop d-flex flex-row w100">
                  {companies.map((company) => (
                    <div key={company.id} className="about-us-companies-desktop-item">
                      {company.element}
                    </div>
                  ))}
                </div>
              </>
            </SafeArea>
            <div className="about-us-companies-mobile">
              {companies.map((company) => (
                <div key={company.id} className="about-us-companies-mobile-item">
                  {company.element}
                </div>
              ))}
            </div>
          </>
        </>
      </Wrapper >
    </>
  )
}
export default AboutUs;