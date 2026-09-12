'use client';
import React from 'react';
import './Talk.css';
import Wrapper from '@/components/basic/wrapper';
import SafeArea from '@/components/basic/safe-area';
import qr from '@/assets/images/qr_ya_toca.png';
import Image from 'next/image';
import { capitalize_first_letter } from '@/constants';
import QuestionBox from '@/components/basic/question-box';

const Talk: React.FC = () => {
  const [isMobile, setIsMobile] = React.useState(false);
  const [response, setResponse] = React.useState('');
  const [loadingPost, setLoadingPost] = React.useState(false);
  const [loadingQuestion, setLoadingQuestion] = React.useState(false);
  const sectionColor = '#000000';
  const sectionTextColor = '#FFFFFF';
  const [responses, setResponses] = React.useState<{ id: string; response: string; timestamp: Date }[]>([]);
  type QuestionId = 1 | 2 | 3;

  const [questions, setQuestions] = React.useState<Record<QuestionId, string>>({
    1: '',
    2: '',
    3: ''
  });

  const [messages, setMessages] = React.useState<Record<QuestionId, { type: 'success' | 'error' } | null>>({
    1: null,
    2: null,
    3: null
  });

  const [ages, setAges] = React.useState<Record<QuestionId, string>>({
    1: '',
    2: '',
    3: ''
  });

  const textareaRefs = {
    1: React.useRef<HTMLTextAreaElement | null>(null),
    2: React.useRef<HTMLTextAreaElement | null>(null),
    3: React.useRef<HTMLTextAreaElement | null>(null),
  };
  // videos
  const videoRef = React.useRef<HTMLVideoElement>(null);
  const videoRefMobile = React.useRef<HTMLVideoElement>(null);
  const [showOverlay, setShowOverlay] = React.useState(true);
  const [fadeOut, setFadeOut] = React.useState(false);

  const handleOverlayClick = () => {
    setFadeOut(true);
    setTimeout(() => {
      setShowOverlay(false);
      isMobile ? videoRefMobile.current?.play() : videoRef.current?.play();
    }, 500);
  };


  React.useEffect(() => {
    if (typeof window === 'undefined') return;

    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };

    checkMobile(); // Initial check

    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const fetchData = async () => {
    try {
      const response = await fetch("/api/opiniones-hero", {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      })
      const data = await response.json();
      setResponses(data.data.map((item: { comentario: string, fecha: string }) => {
        return {
          id: item.fecha,
          response: item.comentario,
          timestamp: new Date(item.fecha)
        }
      }));
    } catch (error) {
      console.log(error);
    }
  }
  const handleResponse = (e: any) => {
    const value = e.target.value;
    if (value.length <= 30) {
      setResponse(value);
    }
  };
  const submitResponse = async () => {
    if (response) {
      try {
        setLoadingPost(true);
        // save to the db
        const res = await fetch("/api/opiniones-hero", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ message: response }),
        })
        const fecha = new Date();
        setLoadingPost(false);
        setResponses((prev) => [{ id: fecha.toISOString(), response, timestamp: fecha }, ...prev])
        setResponse('');
      } catch (error) {
        console.log(error);
        setLoadingPost(false);
      } finally {
        setLoadingPost(false);
      }

    }
  }
  const submitQuestion = async (type: QuestionId) => {
    const value = questions[type];
    const fieldName = `q${type}` as 'q1' | 'q2' | 'q3';
    const age_group = ages[type];

    if (!value) return;

    setLoadingQuestion(true);
    try {
      const response = await fetch("/api/opiniones", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ [fieldName]: value, age_group: age_group }),
      });

      console.log(await response.json());

      setQuestions(prev => ({ ...prev, [type]: '' }));
      setAges(prev => ({ ...prev, [type]: '' }));
      const el = textareaRefs[type].current;
      if (el) el.style.height = 'auto';

      setMessages(prev => ({ ...prev, [type]: { type: 'success' } }));
      setTimeout(() => {
        setMessages(prev => ({ ...prev, [type]: null }));
      }, 1000);
    } catch (err) {
      console.log(err);
      setMessages(prev => ({ ...prev, [type]: { type: 'error' } }));
    } finally {
      setLoadingQuestion(false);
    }
  };


  React.useEffect(() => {
    if (typeof window === 'undefined') return;

    const hash = window.location.hash;
    if (hash) {
      const el = document.querySelector(hash);
      if (el) {
        setTimeout(() => {
          el.scrollIntoView({ behavior: 'smooth' });
        }, 100); // small delay to ensure DOM is ready
      }
    }
  }, []);

  React.useEffect(() => {
    const interval = setInterval(() => {
      fetchData(); // your function to fetch responses
    }, 10000); // 10,000 ms = 10 seconds

    // Fetch immediately on mount
    fetchData();

    // Cleanup interval on unmount
    return () => clearInterval(interval);
  }, []);
  return (
    <>
      <Wrapper
        color={sectionColor}
        textColor={sectionTextColor}
        hasFooter={false}
        logoColor={sectionTextColor}
      >
        <>
          <>
            <div className="talk-questions" id="questions">
              <SafeArea>
                <>
                  <QuestionBox
                    title={<div className="q-input-title">
                      <div className="q-input-title">¿Qué %$#!@</div>
                      <div className="q-input-title">hacemos con el Perú?</div>
                    </div>}
                    value={questions[1]}
                    onChange={(e) => setQuestions(prev => ({ ...prev, [1]: e.target.value }))}
                    onSubmit={() => submitQuestion(1)}
                    textareaRef={textareaRefs[1]}
                    message={messages[1] && { ...messages[1], question: 1 }}
                    loading={loadingQuestion}
                    edad={ages[1]}
                    setEdad={(e) => setAges(prev => ({ ...prev, [1]: e }))}
                    questionId={1}
                  />

                  <QuestionBox
                    title={<div className="q-input-title">
                      <div className="q-input-title">Lo que más me jode del Perú...</div>
                    </div>}
                    value={questions[2]}
                    onChange={(e) => setQuestions(prev => ({ ...prev, [2]: e.target.value }))}
                    onSubmit={() => submitQuestion(2)}
                    textareaRef={textareaRefs[2]}
                    message={messages[2] && { ...messages[2], question: 2 }}
                    loading={loadingQuestion}
                    edad={ages[2]}
                    setEdad={(e) => setAges(prev => ({ ...prev, [2]: e }))}
                    questionId={2}
                  />

                  <QuestionBox
                    title={<div className="q-input-title">
                      <div className="q-input-title">No intentaría huir del Perú si...</div>
                    </div>}
                    value={questions[3]}
                    onChange={(e) => setQuestions(prev => ({ ...prev, [3]: e.target.value }))}
                    onSubmit={() => submitQuestion(3)}
                    textareaRef={textareaRefs[3]}
                    message={messages[3] && { ...messages[3], question: 3 }}
                    loading={loadingQuestion}
                    edad={ages[3]}
                    setEdad={(e) => setAges(prev => ({ ...prev, [3]: e }))}
                    questionId={3}
                  />
                  {/* <div className="q-item w100 gap">
                    <div className="q-input-title">Mándanos lo que quieras por <a href="https://wa.me/51922824173" target="_blank" style={{
                      borderBottom: '1px solid white',
                      paddingBottom: 8
                    }}>Whatsapp</a></div>
                    <div className="q-input-p1" />
                    <div className='q-qr'><Image width={120} height={120} src={qr} alt="qr" /></div>
                  </div> */}
                </>
              </SafeArea>
            </div>
            <div className='talk-content'>
              <SafeArea>
                <div className='d-flex flex-row w100 gap'>
                  <div className="talk-content-p1" />
                  <div className="talk-content-p2">
                    <div className="fw700">
                      No metiste tu cuchara y ahora
                    </div>
                    <div>
                      ...hay piña en tu pizza.
                    </div>
                    <div>
                      ...te toca salir a hablar en la expo grupal.
                    </div>
                    <div>
                      ...te sentaron al medio en el carro.
                    </div>
                    <div className="talk-content-divider" />
                    <div><span className="fw700">En democracia pasa lo mismo:</span> ser parte es opinar, y ser escuchado. Sino, fuiste: otro elige por ti.</div>
                  </div>
                  <div className="talk-content-p2-mobile">
                    <div>
                      <span className="fw700">No metiste tu cuchara y ahora,</span> hay piña en tu pizza, te toca salir a hablar en la expo grupal, te sentaron al medio en el carro.
                    </div>
                    <div className="talk-content-divider" />
                    <div><span className="fw700">En democracia pasa lo mismo:</span> ser parte es opinar, y ser escuchado. Sino, fuiste: otro elige por ti.</div>
                  </div>
                </div>
              </SafeArea>
            </div>
            <div className="talk-header">
              <SafeArea>
                <div className='talk-header-wrapper w100 gap'>
                  <div className="talk-p1">
                    <div className="thunder-fw-bold-lc talk-p1-title uppercase">No hacer nada por el Perú es el verdadero</div>
                    <input
                      onChange={handleResponse}
                      onKeyDown={(e) => e.key === 'Enter' && submitResponse()}
                      value={response}
                      className='talk-input'
                      placeholder="Escribe tu respuesta aquí..."
                    />
                    <div className="w100 tar textWhite mt8">{response.length}/30</div>
                    {response && <button
                      disabled={loadingPost}
                      onClick={submitResponse}
                      className={`talk-save-button pointer thunder-fw-bold-lc uppercase ${loadingPost ? 'disabled' : ''}`}>Guardar</button>}
                  </div>
                  <div className="talk-p2" />
                  <div className="talk-p3">
                    <div className="talk-p3-title thunder-fw-lc uppercase">Lo que la gente dice...</div>
                    {responses
                      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
                      .map((response, index) => (
                        <div key={index} className="talk-p3-response">{capitalize_first_letter(response.response)}</div>
                      ))}
                  </div>
                </div>
              </SafeArea>
            </div>
            <div className="talk-cabildos">
              <SafeArea>
                <>
                  <div className="c-name">Cabildos</div>
                  <div className="d-flex flex-row w100 gap">
                    <div className="w100 gap c-content">
                      <div className="fw700 c-text">
                        Llama a tu mancha, vamos a salvar el país.
                      </div>
                      <div className="c-text">
                        (Bueno, tampoco, tampoco)
                      </div>
                      <div className="c-content-divider" />
                      <div className="fw400 c-text">
                        Una tardecita con tus patas, conversar sin presiones, y hablar de las cosas que nos importan y que los de arriba deben escuchar antes de que el país se vaya al caño.
                      </div>
                      {/* <div className="c-content-divider" />
                                            <div className="fw400 c-text">
                                                <span style={{
                                                    borderBottom: '2px solid #000000'
                                                }}>Descarga el tutorial</span> y a poner las cosas sobre la mesa. Sin floro, sin discursos.
                                            </div> */}
                    </div>
                    <div className="c-p1" />
                  </div>
                  {!isMobile && <div className="c-video-desktop-wrapper">
                    {showOverlay && (
                      <div
                        className={`video-overlay ${fadeOut ? 'hidden' : ''}`}
                        onClick={handleOverlayClick}
                      />
                    )}
                    <video
                      ref={videoRef}
                      className="c-video-desktop"
                      src="https://ya-toca-web-imgs.nyc3.cdn.digitaloceanspaces.com/habla.mp4"
                      controls
                    />
                  </div>}
                </>
              </SafeArea>
            </div>
            {isMobile && <div className='talk-video-mobile'>
              {showOverlay && (
                <div
                  className={`video-overlay-mobile ${fadeOut ? 'fade-out' : ''}`}
                  onClick={handleOverlayClick}
                />
              )}
              <video
                ref={videoRefMobile}
                className="c-video-mobile"
                src="https://ya-toca-web-imgs.nyc3.cdn.digitaloceanspaces.com/habla.mp4"
                controls
              />
            </div>}
          </>
        </>
      </Wrapper >
    </>
  )
}
export default Talk;